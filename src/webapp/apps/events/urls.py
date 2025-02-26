from django.urls import path

from .views import home, ListView, CreateView, UpdateView


urlpatterns = [
    path('list', ListView.as_view(), name='list'),
    path('create', CreateView.as_view(), name='create'),
    path('<slug:slug>', UpdateView.as_view(), name='update'),
    path('', home),
]
