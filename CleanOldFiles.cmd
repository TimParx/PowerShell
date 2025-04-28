@echo off
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "datestamp=%YYYY%%MM%%DD%" & set "timestamp=%HH%%Min%%Sec%"
set "fullstamp=%YYYY%-%MM%-%DD%_%HH%:%Min%:%Sec%"


echo  ################## 	> "e:\scripts\filestoremove.txt"
echo  # FF_OC_GLO_PROD #			Check done: %YYYY%-%MM%-%DD%  %HH%:%Min%:%Sec%	>> "e:\scripts\filestoremove.txt"
echo  ################## 	>> "e:\scripts\filestoremove.txt"

echo. >> "e:\scripts\filestoremove.txt"
echo  ----------------------------------------------------------------------------------------------------------- >> "e:\scripts\filestoremove.txt"
echo. >> "e:\scripts\filestoremove.txt"

forfiles /p "E:\FTP\Kunder\Opus\FF_OC_GLO_PROD\PROD\OPUS\INVOICES" /s /m *.* /D -14 /C "cmd /c echo @path @fdate >> e:\scripts\filestoremove.txt"
forfiles /p "E:\FTP\Kunder\Opus\FF_OC_GLO_PROD\PROD\OPUS\INVOICES" /s /m *.* /D -14 /C "cmd /c del @path"



set From=donotreply-se@exelaonline.com
set To=tomas.skoglund@exelaonline.com
set Subj=Files older than 14 days in FF_OC_GLO_PROD
set body=

E:\Scripts\bmail.exe -s 10.34.110.200 -t %To% -f %From% -h -a "%Subj%" -c -m e:\scripts\filestoremove.txt

del e:\scripts\filestoremove.txt
