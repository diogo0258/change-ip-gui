@Echo Off
del interfaces.txt
For /f "skip=2 tokens=4*" %%a In ('NetSh Interface Show Interface') Do (
    echo %%a>> interfaces.txt
)
Exit /B
