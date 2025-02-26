from django.contrib.gis.forms.widgets import BaseGeometryWidget
from django.contrib.gis.geometry import json_regex


class GeometryWidget(BaseGeometryWidget):
    template_name = "events/widgets/geometry.html"
    default_lon = -119.49662112970556
    default_lat = 49.887338062986295
    default_zoom = 14

    def serialize(self, value):
        return value.json if value else ""

    def deserialize(self, value):
        geom = super().deserialize(value)
        # GeoJSON assumes WGS84 (4326). Use the map's SRID instead.
        if geom and json_regex.match(value) and self.map_srid != 4326:
            geom.srid = self.map_srid
        return geom

    def __init__(self, attrs=None):
        super().__init__()
        for key in ("default_lon", "default_lat", "default_zoom"):
            self.attrs[key] = getattr(self, key)
        if attrs:
            self.attrs.update(attrs)

