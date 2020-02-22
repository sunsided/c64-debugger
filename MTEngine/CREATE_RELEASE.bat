@echo -------------------------
@echo  -=(  BUILD RELEASE  )=-
@echo -------------------------
call CLEAN_RELEASE.bat
call BUILD.bat
call COPY_RELEASE.bat
@echo DONE!
@echo.
@echo ______________________________________
@echo.
@echo    -=(  RELEASE BUILD FINISHED  )=-
@echo ______________________________________
@echo.
@pause