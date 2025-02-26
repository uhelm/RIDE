from django.shortcuts import render

def home(request):

    return render(request, 'ride/base.html')


def cameras(request):

    return render(request, 'ride/cameras.html')