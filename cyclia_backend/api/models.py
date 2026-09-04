from django.db import models
from django.contrib.auth.models import User

class UserProfile(models.Model):
    OBJECTIVE_CHOICES = [
        ('track', 'Suivi de cycle'),
        ('pregnancy', 'Désir de grossesse'),
        ('contraception', 'Contraception naturelle'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    birth_date = models.DateField(null=True, blank=True)
    average_cycle_length = models.IntegerField(default=28)
    average_period_length = models.IntegerField(default=5)
    is_irregular_declared = models.BooleanField(default=False)
    objective = models.CharField(max_length=50, choices=OBJECTIVE_CHOICES, default='track')
    privacy_enabled = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Profile of {self.user.username}"


class Cycle(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='cycles')
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-start_date']

    def __str__(self):
        return f"Cycle for {self.user.username} (Start: {self.start_date})"


class DailyEntry(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='daily_entries')
    date = models.DateField()
    
    # Symptoms
    flow_intensity = models.IntegerField(null=True, blank=True)  # 0: Aucun, 1: Léger, 2: Moyen, 3: Abondant
    pain_intensity = models.IntegerField(null=True, blank=True)  # 0: Aucun, 1: Léger, 2: Moyen, 3: Intense
    mood = models.CharField(max_length=100, null=True, blank=True)      # happy, sad, anxious, irritable, calm, etc.
    energy_level = models.IntegerField(null=True, blank=True)    # 1 (Très bas) à 5 (Très élevé)
    notes = models.TextField(null=True, blank=True)
    
    # Fertility data (advanced)
    temperature = models.FloatField(null=True, blank=True)       # Température basale en °C
    cervical_mucus = models.CharField(max_length=50, null=True, blank=True)  # dry, sticky, creamy, watery, egg_white
    lh_test = models.CharField(max_length=20, null=True, blank=True)       # negative, positive

    # New fields inspired by Flo
    physical_symptoms = models.TextField(null=True, blank=True) # Comma separated values
    had_sex = models.BooleanField(default=False)
    sex_details = models.CharField(max_length=50, null=True, blank=True) # protected, unprotected
    used_contraception = models.BooleanField(default=False)
    contraception_method = models.CharField(max_length=100, null=True, blank=True) # condom, pill, emergency, etc.

    # Lifestyle & Body
    weight = models.FloatField(null=True, blank=True)
    sleep_hours = models.FloatField(null=True, blank=True)
    stress_level = models.IntegerField(null=True, blank=True) # 1-5
    water_intake = models.IntegerField(default=0) # Number of glasses
    pill_taken = models.BooleanField(default=False)
    alcohol_consumption = models.BooleanField(default=False)
    exercise_intensity = models.CharField(max_length=50, null=True, blank=True) # none, light, moderate, intense

    # Skin & Hair
    skin_condition = models.CharField(max_length=50, null=True, blank=True) # clear, oily, dry, spots
    hair_condition = models.CharField(max_length=50, null=True, blank=True) # normal, oily, dry, hair_loss

    class Meta:
        unique_together = ('user', 'date')
        ordering = ['-date']

    def __str__(self):
        return f"Entry on {self.date} for {self.user.username}"
