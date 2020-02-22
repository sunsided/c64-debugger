@For /F "tokens=1,2,3 delims=- " %%A in ('Date /t') do @( 
Set Day=%%A
Set Month=%%B
Set Year=%%C
Set AllDate=%%A%%B%%C
)
@For /F "tokens=1,2 delims=: " %%A in ('Time /t') do @( 
Set Hour=%%A
Set Minutes=%%B
Set AllHour=%%A%%B
)

@Set OutDir=.\..\_MTEngine-REL-%AllDate%-%AllHour%

mkdir %OutDir%
mkdir %OutDir%\Resources
mkdir %OutDir%\Documents
mkdir %OutDir%\log
mkdir %OutDir%\Temp
copy .\bin\Release\*.dll %OutDir%\
copy .\bin\Release\*.exe %OutDir%\
copy .\_RUNTIME_\*.dll %OutDir%\
xcopy /E .\_RUNTIME_\Resources\*.* %OutDir%\Resources
@echo DONE!
