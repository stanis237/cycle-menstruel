from rest_framework import serializers
from django.contrib.auth.models import User
from .models import UserProfile, Cycle, DailyEntry

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = ['birth_date', 'average_cycle_length', 'average_period_length', 'is_irregular_declared', 'objective', 'privacy_enabled', 'is_discreet_mode', 'is_premium']


class UserSerializer(serializers.ModelSerializer):
    profile = UserProfileSerializer(required=False)

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'password', 'profile']
        extra_kwargs = {
            'password': {'write_only': True},
            'email': {'required': True}
        }

    def create(self, validated_data):
        profile_data = validated_data.pop('profile', {})
        password = validated_data.pop('password')
        
        # We use email as the username if username is not explicitly provided, or vice-versa.
        # Let's ensure username is unique.
        user = User.objects.create_user(
            username=validated_data.get('username'),
            email=validated_data.get('email'),
            password=password
        )
        
        UserProfile.objects.create(user=user, **profile_data)
        return user

    def update(self, instance, validated_data):
        profile_data = validated_data.pop('profile', {})
        
        # Update user fields
        instance.email = validated_data.get('email', instance.email)
        instance.save()
        
        # Update or create profile fields (Safer)
        profile, created = UserProfile.objects.get_or_create(user=instance)
        for attr, value in profile_data.items():
            setattr(profile, attr, value)
        profile.save()
        
        return instance


class CycleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Cycle
        fields = ['id', 'start_date', 'end_date', 'is_active']
        read_only_fields = ['id']

    def create(self, validated_data):
        user = self.context['request'].user
        
        # Deactivate previous active cycles if a new one is being started
        Cycle.objects.filter(user=user, is_active=True).update(is_active=False)
        
        cycle = Cycle.objects.create(user=user, **validated_data)
        return cycle


class DailyEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyEntry
        fields = [
            'id', 'date', 'flow_intensity', 'pain_intensity', 
            'mood', 'energy_level', 'notes', 'temperature', 
            'cervical_mucus', 'lh_test', 'physical_symptoms', 'had_sex',
            'sex_details', 'used_contraception', 'contraception_method',
            'weight', 'sleep_hours', 'stress_level',
            'water_intake', 'alcohol_consumption', 'exercise_intensity',
            'skin_condition', 'hair_condition', 'pill_taken'
        ]
        read_only_fields = ['id']

    def create(self, validated_data):
        user = self.context['request'].user
        date = validated_data.get('date')
        
        # Update or create based on unique user-date
        entry, created = DailyEntry.objects.update_or_create(
            user=user, date=date,
            defaults=validated_data
        )
        return entry
