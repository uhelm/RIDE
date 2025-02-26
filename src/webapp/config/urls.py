from debug_toolbar.toolbar import debug_toolbar_urls
from django.contrib import admin
from django.urls import path, include

from apps.ride.views import home, cameras
from apps.events import urls as event_urls


urlpatterns = [
    path('admin/', admin.site.urls),
    path('events/', include((event_urls, 'events'), namespace='events')),
    path('cameras/', cameras),
    path('', home),
] + debug_toolbar_urls()
