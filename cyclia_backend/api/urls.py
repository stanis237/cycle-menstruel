from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from .views import RegisterView, ProfileView, CycleViewSet, DailyEntryViewSet, PredictionsView

router = DefaultRouter()
router.register(r'cycles', CycleViewSet, basename='cycle')
router.register(r'daily-entries', DailyEntryViewSet, basename='dailyentry')

urlpatterns = [
    # Auth endpoints
    path('auth/register/', RegisterView.as_view(), name='register'),
    path('auth/login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # Profile endpoints
    path('profile/', ProfileView.as_view(), name='profile'),
    
    # Predictions endpoint
    path('predictions/', PredictionsView.as_view(), name='predictions'),
    
    # ViewSets (Cycles, DailyEntries)
    path('', include(router.urls)),
]
