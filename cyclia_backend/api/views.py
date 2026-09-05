import math
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
        except (ValueError, TypeError):
            return Response({"error": "Format de date invalide. Utilisez YYYY-MM-DD."}, status=status.HTTP_400_BAD_REQUEST)
        
        # Deactivate all active cycles for this user first
        Cycle.objects.filter(user=user, is_active=True).update(is_active=False)

        # Check if cycle on this exact day already exists or create it
        cycle, created = Cycle.objects.get_or_create(
            user=user, start_date=start_date,
            defaults={'is_active': True}
        )
        
        if not created:
            cycle.is_active = True
            cycle.save()
            
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
        is_irregular = profile.is_irregular_declared if profile else False

        # Get all cycles sorted by start_date ascending to analyze history
        cycles = list(Cycle.objects.filter(user=user).order_by('start_date'))
        
        if not cycles:
            return Response({
                "message": "Aucun historique de cycle trouvé. Veuillez ajouter un cycle pour voir les prédictions.",
                "predictions": []
            }, status=status.HTTP_200_OK)
            
        # Dynamically compute average cycle length and regularity
        cycle_lengths = []
        std_dev = 7 if is_irregular else 0 # Default high std_dev if declared irregular

        if len(cycles) >= 2:
            for i in range(1, len(cycles)):
                diff = (cycles[i].start_date - cycles[i-1].start_date).days
                if 15 <= diff <= 90:
                    cycle_lengths.append(diff)

            if cycle_lengths:
                avg_cycle = sum(cycle_lengths) / len(cycle_lengths)

                # Calculate Standard Deviation
                variance = sum((x - avg_cycle) ** 2 for x in cycle_lengths) / len(cycle_lengths)
                std_dev = math.sqrt(variance)

                # A cycle is often considered irregular if variation is > 4 days
                # Or if the user declared it irregular
                if std_dev > 4 or is_irregular:
                    is_irregular = True
                
                avg_cycle = int(avg_cycle)
        elif is_irregular:
            # If only 1 cycle but user declared irregular, we assume a standard deviation of 7 days
            std_dev = 7

        # Latest cycle
        latest_cycle = cycles[-1]
        latest_start = latest_cycle.start_date
        
        # Calculate current cycle progress
        today = datetime.now().date()
        days_since_start = (today - latest_start).days

        # If the latest cycle started a long time ago (more than average length + buffer),
        # we treat predictions from "today" as base for UX consistency
        prediction_base_date = latest_start
        if days_since_start > (avg_cycle + 14):
            # We predict relative to what should be the next cycle if they missed logging
            cycles_missed = days_since_start // avg_cycle
            prediction_base_date = latest_start + timedelta(days=cycles_missed * avg_cycle)

        current_day_of_cycle = days_since_start + 1
        
        # Determine current phase logic
        ovulation_day_index = avg_cycle - 14
        fertile_start_index = ovulation_day_index - 5
        fertile_end_index = ovulation_day_index + 1
        
        current_phase = "Phase lutéale"
        if 1 <= current_day_of_cycle <= avg_period:
            current_phase = "Règles (Menstruation)"
        elif avg_period < current_day_of_cycle < fertile_start_index:
            current_phase = "Phase folliculaire"
        elif fertile_start_index <= current_day_of_cycle <= fertile_end_index:
            current_phase = "Fenêtre fertile (Ovulation)"
        elif current_day_of_cycle > avg_cycle:
            current_phase = "Retard de cycle"

        predictions = []
        
        # Generate predictions for the next 3 cycles
        for i in range(1, 4):
            # Base predicted start
            base_pred_start = prediction_base_date + timedelta(days=i * avg_cycle)

            # Ensure predictions are in the future
            while base_pred_start <= today:
                base_pred_start += timedelta(days=avg_cycle)

            # For irregular cycles, provide a range
            # We limit the uncertainty buffer to 3 days max on each side (total 6 days range)
            # to avoid overly wide predictions while accounting for irregularity.
            raw_buffer = max(2, int(std_dev)) * i
            buffer = min(raw_buffer, 3)

            earliest_start = base_pred_start - timedelta(days=buffer)
            latest_pred_start = base_pred_start + timedelta(days=buffer)

            pred_end = base_pred_start + timedelta(days=avg_period - 1)
            pred_ovulation = base_pred_start - timedelta(days=14)

            # Fertility window is also wider if irregular
            f_buffer = buffer // 2
            pred_fertile_start = pred_ovulation - timedelta(days=5 + f_buffer)
            pred_fertile_end = pred_ovulation + timedelta(days=1 + f_buffer)
            
            predictions.append({
                "cycle_number": i,
                "predicted_start": base_pred_start.strftime("%Y-%m-%d"),
                "earliest_predicted_start": earliest_start.strftime("%Y-%m-%d"),
                "latest_predicted_start": latest_pred_start.strftime("%Y-%m-%d"),
                "predicted_end": pred_end.strftime("%Y-%m-%d"),
                "predicted_ovulation": pred_ovulation.strftime("%Y-%m-%d"),
                "predicted_fertile_start": pred_fertile_start.strftime("%Y-%m-%d"),
                "predicted_fertile_end": pred_fertile_end.strftime("%Y-%m-%d"),
            })
            
        # Return details
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
                "is_irregular": is_irregular,
                "cycle_regularity_std_dev": round(std_dev, 2),
                "ovulation_date": current_cycle_ovulation.strftime("%Y-%m-%d"),
                "fertile_window_start": current_cycle_fertile_start.strftime("%Y-%m-%d"),
                "fertile_window_end": current_cycle_fertile_end.strftime("%Y-%m-%d"),
            },
            "predictions": predictions,
            "analysis": {
                "cycle_count": len(cycles),
                "regularity_status": "Irrégulier" if is_irregular else "Régulier",
                "variation_days": round(std_dev, 1)
            }
        })

class LeaderboardView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        # In a real app, this would query the DB for top security scores
        # Here we return simulated anonymous data for the "Social Proof" effect
        data = [
            {"username": "Louve_Sereine", "score": 100, "badges": 12, "is_me": False},
            {"username": "Etoile_Protegee", "score": 98, "badges": 10, "is_me": False},
            {"username": "Rose_Vigilante", "score": 95, "badges": 9, "is_me": False},
            {"username": request.user.username, "score": 85, "badges": 5, "is_me": True},
            {"username": "Iris_Libre", "score": 82, "badges": 4, "is_me": False},
            {"username": "Nymphe_Bio", "score": 78, "badges": 3, "is_me": False},
        ]
        return Response(data)
