import uuid

from django.db import models
from django.core.serializers.json import DjangoJSONEncoder
from django.contrib.gis.db import models as gis

from .enums import EventType, EventSubtype, Severity, Status


class Event(models.Model):

    uuid = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    id = models.CharField(max_length=20, unique=True, blank=False)

    created = models.DateTimeField(auto_now_add=True, editable=False)
    last_updated = models.DateTimeField(auto_now=True, editable=False)
    metadata = models.JSONField(default=dict, encoder=DjangoJSONEncoder, editable=False)

    event_type = models.CharField(max_length=30, choices=EventType, blank=False, null=False)
    event_subtype = models.CharField(max_length=30, choices=EventSubtype, blank=False, null=False)

    status = models.CharField(max_length=20, choices=Status, blank=False, null=False)
    severity = models.CharField(max_length=20, choices=Severity.choices, blank=False, null=False)
    is_closure = models.BooleanField(default=False)

    geometry = gis.GeometryField(blank=True, null=True)

    headline = models.CharField(max_length=100, blank=False, null=False)
    description = models.TextField()

    def save(self, *args, **kwargs):
        if self._state.adding:
            last_id = Event.objects.values_list('id', flat=True).order_by('-id').first()
            _, id = last_id.split('-')
            self.id = f'DBC-{int(id) + 1}'
        try:
            super().save(*args, **kwargs)
        except Exception as e:
            print(e)
