from django.forms import ModelForm, CharField
from django.contrib.gis.forms import GeometryField

from .models import Event
from .widgets import GeometryWidget


class EventForm(ModelForm):

    template_name = 'forms/event.html'

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        if self.instance._state.adding:
            del self.fields['id']

    id = CharField(disabled=True)
    geometry = GeometryField(widget=GeometryWidget)

    class Meta:
        model = Event
        fields = "__all__"
