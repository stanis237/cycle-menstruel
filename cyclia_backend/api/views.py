from django.shortcuts import render
from rest_framework import status, viewsets, permissions, views
from rest_framework.response import Response
from rest_framework.decorators import action
from django.contrib.auth.models import User
from .models import UserProfile, Cycle, DailyEntry
from .serializers import UserSerializer, UserProfileSerializer, CycleSerializer, DailyEntrySerializer
from datetime import datetime, timedelta

class RegisterView(views.APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = UserSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            return Response({
                "message": "Utilisatrice créée avec succès.",
                "user": {
                    "id": user.id,
                    "username": user.username,
                    "email": user.email
                }
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ProfileView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)

    def put(self, request):
        serializer = UserSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class CycleViewSet(viewsets.ModelViewSet):
    serializer_class = CycleSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Cycle.objects.filter(user=self.request.user)

    @action(detail=False, methods=['post'], url_path='start-or-update')
    def start_or_update(self, request):
        """
        Starts a new cycle, deactivating previous ones.
        If a cycle already exists for the given start_date, returns/updates it.
        """
        user = request.user
        start_date_str = request.data.get('start_date')
        if not start_date_str:
            return Response({"error": "La date de début (start_date) est requise."}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            start_date = datetime.strptime(start_date_str, "%Y-%m-%d").date()
        except ValueError:
            return Response({"error": "Format de date invalide. Utilisez YYYY-MM-DD."}, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if cycle on this exact day already exists
        cycle, created = Cycle.objects.get_or_create(
            user=user, start_date=start_date,
            defaults={'is_active': True}
        )
        
        if not created:
            cycle.is_active = True
            cycle.save()
            
        # Deactivate all OTHER cycles
        Cycle.objects.filter(user=user, is_active=True).exclude(id=cycle.id).update(is_active=False)
        
        serializer = self.get_serializer(cycle)
        return Response(serializer.data, status=status.HTTP_200_OK if not created else status.HTTP_201_CREATED)


class DailyEntryViewSet(viewsets.ModelViewSet):
    serializer_class = DailyEntrySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return DailyEntry.objects.filter(user=self.request.user)

    @action(detail=False, methods=['get', 'post'], url_path='by-date')
    def by_date(self, request):
        user = request.user
        date_str = request.query_params.get('date') or request.data.get('date')
        
        if not date_str:
            return Response({"error": "La date est requise."}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            date_val = datetime.strptime(date_str, "%Y-%m-%d").date()
        except ValueError:
            return Response({"error": "Format de date invalide. Utilisez YYYY-MM-DD."}, status=status.HTTP_400_BAD_REQUEST)
        
        if request.method == 'GET':
            try:
                entry = DailyEntry.objects.get(user=user, date=date_val)
                serializer = self.get_serializer(entry)
                return Response(serializer.data)
            except DailyEntry.DoesNotExist:
                return Response({}, status=status.HTTP_200_OK) # Return empty object if no entry exists
                
        elif request.method == 'POST':
            # Create or update daily entry
            serializer = self.get_serializer(data=request.data, context={'request': request})
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data, status=status.HTTP_200_OK)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class PredictionsView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        profile = getattr(user, 'profile', None)
        
        avg_cycle = profile.average_cycle_length if profile else 28
        avg_period = profile.average_period_length if profile else 5
        
        # Get all cycles sorted by start_date ascending to analyze history
        cycles = list(Cycle.objects.filter(user=user).order_by('start_date'))
        
        if not cycles:
            return Response({
                "message": "Aucun historique de cycle trouvé. Veuillez ajouter un cycle pour voir les prédictions.",
                "predictions": []
            }, status=status.HTTP_200_OK)
            
        # Dynamically compute average cycle length if we have at least 2 cycles
        if len(cycles) >= 2:
            intervals = []
            for i in range(1, len(cycles)):
                diff = (cycles[i].start_date - cycles[i-1].start_date).days
                # Filter out outlier cycle intervals (e.g. < 15 days or > 90 days)
                if 15 <= diff <= 90:
                    intervals.append(diff)
            if intervals:
                avg_cycle = int(sum(intervals) / len(intervals))
                
        # Latest cycle
        latest_cycle = cycles[-1]
        latest_start = latest_cycle.start_date
        
        # Calculate current cycle progress
        today = datetime.now().date()
        days_since_start = (today - latest_start).days
        current_day_of_cycle = days_since_start + 1
        
        # Determine current phase
        # Standard: 
        # Menstruation: days 1 to avg_period
        # Follicular (pre-fertile): days avg_period + 1 to ovulation_day - 6
        # Fertile Window: ovulation_day - 5 to ovulation_day + 1
        # Luteal: ovulation_day + 2 to next_start - 1
        ovulation_day_index = avg_cycle - 14  # Day of ovulation relative to cycle start (e.g. Day 14 for 28-day cycle)
        fertile_start_index = ovulation_day_index - 5 # Day 9
        fertile_end_index = ovulation_day_index + 1    # Day 15
        
        current_phase = "Phase lutéale"
        if 1 <= current_day_of_cycle <= avg_period:
            current_phase = "Règles (Menstruation)"
        elif avg_period < current_day_of_cycle < fertile_start_index:
            current_phase = "Phase folliculaire"
        elif fertile_start_index <= current_day_of_cycle <= fertile_end_index:
            current_phase = "Fenêtre fertile (Ovulation)"
            
        predictions = []
        
        # Generate predictions for the next 3 cycles
        for i in range(1, 4):
            pred_start = latest_start + timedelta(days=i * avg_cycle)
            pred_end = pred_start + timedelta(days=avg_period - 1)
            pred_ovulation = pred_start - timedelta(days=14)
            pred_fertile_start = pred_ovulation - timedelta(days=5)
            pred_fertile_end = pred_ovulation + timedelta(days=1)
            
            predictions.append({
                "cycle_number": i,
                "predicted_start": pred_start.strftime("%Y-%m-%d"),
                "predicted_end": pred_end.strftime("%Y-%m-%d"),
                "predicted_ovulation": pred_ovulation.strftime("%Y-%m-%d"),
                "predicted_fertile_start": pred_fertile_start.strftime("%Y-%m-%d"),
                "predicted_fertile_end": pred_fertile_end.strftime("%Y-%m-%d"),
            })
            
        # Also return dynamic details for the current active cycle
        current_cycle_ovulation = latest_start + timedelta(days=ovulation_day_index)
        current_cycle_fertile_start = current_cycle_ovulation - timedelta(days=5)
        current_cycle_fertile_end = current_cycle_ovulation + timedelta(days=1)
        
        return Response({
            "current_cycle": {
                "start_date": latest_start.strftime("%Y-%m-%d"),
                "current_day": current_day_of_cycle,
                "current_phase": current_phase,
                "average_cycle_length": avg_cycle,
                "average_period_length": avg_period,
                "ovulation_date": current_cycle_ovulation.strftime("%Y-%m-%d"),
                "fertile_window_start": current_cycle_fertile_start.strftime("%Y-%m-%d"),
                "fertile_window_end": current_cycle_fertile_end.strftime("%Y-%m-%d"),
            },
            "predictions": predictions
        })
