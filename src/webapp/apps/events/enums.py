from django.db import models


class EventType(models.TextChoices):
    CONSTRUCTION = 'CONSTRUCTION', 'Construction'
    INCIDENT = 'INCIDENT', 'Incident'
    SPECIAL_EVENT = 'SPECIAL_EVENT', 'Special event'
    WEATHER_CONDITION = 'WEATHER_CONDITION', 'Weather condition'
    ROAD_CONDITION = 'ROAD_CONDITION', 'Road condition'


class EventSubtype(models.TextChoices):
    ALMOST_IMPASSABLE =   'ALMOST_IMPASSABLE', 'Almost impassable',
    FIRE =                'FIRE', 'Fire'
    HAZARD =              'HAZARD', 'Hazard'
    ROAD_CONSTRUCTION =   'ROAD_CONSTRUCTION', 'Road construction'
    ROAD_MAINTENANCE =    'ROAD_MAINTENANCE', 'Road maintenance'
    PARTLY_ICY =          'PARTLY_ICY', 'Partly icy'
    ICE_COVERED =         'ICE_COVERED', 'Ice covered'
    SNOW_PACKED =         'SNOW_PACKED', 'Snow packed'
    PARTLY_SNOW_PACKED =  'PARTLY_SNOW_PACKED', 'Partly snow packed'
    MUD =                 'MUD', 'Mud'
    PLANNED_EVENT =       'PLANNED_EVENT', 'Planned event'
    POOR_VISIBILITY =     'POOR_VISIBILITY', 'Poor visiblity'
    PARTLY_SNOW_COVERED = 'PARTLY_SNOW_COVERED', 'Partly snow packed'
    DRIFTING_SNOW =       'DRIFTING_SNOW', 'Drifting snow',
    PASSABLE_WITH_CARE =  'PASSABLE_WITH_CARE', 'Passable with care'


class Status(models.TextChoices):
    ACTIVE = 'ACTIVE'
    INACTIVE = 'INACTIVE'


class Severity(models.TextChoices):
    MINOR = 'MINOR'
    MAJOR = 'MAJOR'
