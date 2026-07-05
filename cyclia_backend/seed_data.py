import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'cyclia_backend.settings')
django.setup()

from django.contrib.auth.models import User
from api.models import UserProfile, Cycle, DailyEntry
from datetime import datetime, timedelta

def seed():
    # Delete existing data to start fresh
    User.objects.filter(username='testuser').delete()
    
    # 1. Create a user
    user = User.objects.create_user(
        username='testuser',
        email='testuser@cyclia.com',
        password='password123'
    )
    print(f"Created user: {user.username}")

    # 2. Create UserProfile
    profile = UserProfile.objects.create(
        user=user,
        birth_date=datetime(1998, 5, 15).date(),
        average_cycle_length=28,
        average_period_length=5,
        objective='track'
    )
    print(f"Created profile for {user.username}")

    # 3. Create historical cycles
    # Cycle 1: Started 58 days ago, lasted 28 days
    c1_start = (datetime.now() - timedelta(days=58)).date()
    c1_end = c1_start + timedelta(days=28)
    Cycle.objects.create(
        user=user,
        start_date=c1_start,
        end_date=c1_end,
        is_active=False
    )
    print(f"Created Cycle 1: {c1_start} to {c1_end}")

    # Cycle 2: Started 30 days ago, lasted 28 days
    c2_start = (datetime.now() - timedelta(days=30)).date()
    c2_end = c2_start + timedelta(days=28)
    Cycle.objects.create(
        user=user,
        start_date=c2_start,
        end_date=c2_end,
        is_active=False
    )
    print(f"Created Cycle 2: {c2_start} to {c2_end}")

    # Cycle 3 (Active): Started 2 days ago (ongoing)
    c3_start = (datetime.now() - timedelta(days=2)).date()
    Cycle.objects.create(
        user=user,
        start_date=c3_start,
        is_active=True
    )
    print(f"Created Active Cycle: {c3_start}")

    # 4. Create some daily entries for the active cycle
    # Day 1 of cycle: Heavy flow, cramps
    DailyEntry.objects.create(
        user=user,
        date=c3_start,
        flow_intensity=3,
        pain_intensity=2,
        mood='irritable',
        energy_level=2,
        notes='Début des règles. Fatigue intense.'
    )
    
    # Day 2 of cycle (yesterday): Medium flow, light cramps
    DailyEntry.objects.create(
        user=user,
        date=c3_start + timedelta(days=1),
        flow_intensity=2,
        pain_intensity=1,
        mood='calm',
        energy_level=3,
        notes='Flux moins abondant.'
    )
    
    # Day 3 of cycle (today): Light flow
    DailyEntry.objects.create(
        user=user,
        date=datetime.now().date(),
        flow_intensity=1,
        pain_intensity=0,
        mood='happy',
        energy_level=4,
        notes='Presque fini. Bonne humeur !'
    )
    print("Created DailyEntries")

if __name__ == '__main__':
    seed()
