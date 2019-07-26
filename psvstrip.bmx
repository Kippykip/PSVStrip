Include "functions.bmx"

'Main Program
Print "PSVStrip v0.2 - http://kippykip.com"
Global Prog:Int = 0

'Are there arguments?
If(Len(AppArgs) > 1)
	If(Lower(AppArgs[1]) = "-dirstrip" And Len(AppArgs) >= 4)
		Prog:Int = 1
	ElseIf(Lower(AppArgs[1]) = "-psvstrip" And Len(AppArgs) >= 4)
		Prog:Int = 2
	ElseIf(Lower(AppArgs[1]) = "-applypsve" And Len(AppArgs) >= 5)
		Prog:Int = 3
	EndIf
EndIf

Select Prog
	Case 1 'DirStrip
		ExportBulk(AppArgs[2], AppArgs[3])
		Print "Success!"
		Delay 5000
	Case 2
		
		Try
			ExportPSV(StripDoubleSlashes(StripExtension(AppArgs[2])), StripDoubleSlashes(StripExtension(AppArgs[3])))
			Print "Export complete!"
			Delay 5000
		Catch ex:Object
			Print "EXCEPTION!: " + ex.toString
		End Try
	Case 3
		Try
			PatchPSVE(StripDoubleSlashes(AppArgs[2]), StripDoubleSlashes(AppArgs[3]), StripDoubleSlashes(AppArgs[4]))
			Print "Export complete!"
			Delay 5000
		Catch ex:Object
			Print "EXCEPTION!: " + ex.toString
		End Try
	Default 'No arguments
		Print "Missing command line!"
		Print ""
		Print "PSVStrip.exe -psvstrip source.psv destination.psv"
		Print "PSVStrip.exe -dirstrip sourcedirectory exportdirectory"
		Print "PSVStrip.exe -applypsve source.psv destination.psv stripdata.psve"
		Print ""
		Print "Definitions:"
		Print "-psvstrip: Strips out license data into external files for checksum purposes."
		Print "-dirstrip: Strips out licensing data from multiple .PSV files in a directory."
		Print "-applypsve: Re-adds the licensing data and header info back to a stripped .PSV file."
		Print ""
		Print "Examples:"
		Print "PSVStrip.exe -psvstrip " + Chr(34) + "C:\CoolGameRips\r4-noiregbhj.psv" + Chr(34) + " " + Chr(34) + "C:\CoolGameRips\r4-noiregbhj_stripped.psv" + Chr(34)
		Print ""
		Print "PSVStrip.exe -dirstrip " + Chr(34) + "C:\CoolGameRips\" + Chr(34) + " " + Chr(34) + "C:\CoolGameRips\StrippedDumps\" + Chr(34)
		Print ""
		Print "PSVStrip.exe -applypsve " + Chr(34) + "C:\CoolGameRips\r4-noiregbhj_stripped.psv" + Chr(34) + " " + Chr(34) + "C:\CoolGameRips\r4-noiregbhj.psv" + Chr(34) + " " + Chr(34) + "C:\CoolGameRips\r4-noiregbhj_stripped.psve" + Chr(34)
		Print ""
		Delay 1000
End Select