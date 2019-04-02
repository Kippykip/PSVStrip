'FF FF 00 01 00 01 04 02 00 00 00 00 00 00 00 00
'https://github.com/FakeShemp/VitaLicenseEditor/issues/3

'Header size is 14 bytes
Global PSV_SearchHeader:UInt[] = [$FF, $FF, $00, $01, $00, $01, $04, $02, $00, $00, $00, $00, $00, $00, $00, $00]
'FF FF 00 01 00 01 04 02 00 00 00 00 00 00 00 00
Const UpdateRate:UInt = 1000
Const ChunkSize:UInt = 8192

'PSVE
'Version:Byte
'NumOfLicenses:Byte
'Header $200
'Unknown $260

'CONTINUOUS * Licenses:Byte
'Offset(with original $200 header included):UInt
'Licence1 $10
'License2 $160

Function StripDoubleSlashes:String(SourceString:String)
	Local NewString:String = SourceString.Replace("/", "\")
	While(NewString.Contains("\\"))
		NewString = NewString.Replace("\\", "\")
	Wend
	If(NewString.EndsWith("\"))
		Return Left(NewString, Len(NewString) - 1)
	Else
		Return NewString
	EndIf
End Function

Function GetFolderPath:String(FilePaths:String[])
	Local NewString:String
	For Local x = 0 To Len(FilePaths) - 2 '(-1, and -1 cause I don't want file name)
		NewString = NewString + FilePaths[x] + "\"
	Next
	Return NewString
End Function

Function GetBaseName:String(FilePath:String)
	Local NewArray:String[] = FilePath.Split("\")
	Local NewString:String = NewArray[Len(NewArray) - 1]
	Return left(NewString, len(NewString) - 4)'Crop the extension
End Function

Function ExportPSV(FilePath:String, ExportPath:String = Null)
	'Optional Export path
	If(ExportPath = Null) Then Throw "No export path specified!"
	If(Lower(FilePath) = Lower(ExportPath)) Then Throw "Export path is the same as the input path!"
	
	Local PSV_SearchPos:Byte = 0 'Increases if a pattern matches
	'Todo
	Print "Loading '" + FilePath + ".psv'..."
	Local BaseFile:TStream = ReadStream(FilePath + ".psv")
	If Not(BaseFile) Then Throw "Failed to read '" + FilePath + ".psv" + "'."
	
	Local ExportFile:TStream = WriteStream(ExportPath + ".psv")
	If Not(ExportFile) Then Throw "Failed to write '" + ExportPath + ".psv" + "'."
	
	Local PSV_Meta:TStream = WriteStream(ExportPath + ".psve")
	If Not(PSV_Meta) Then Throw "Failed to write '" + ExportPath + ".psve" + "'."
	
	Local LicenseCount:Byte = 0 'How many licenses were found
	Local Timer:UInt = MilliSecs() ' Updates every second
	Local LicenseArray:UInt[]
	
	'Check if it has a PSV\0 header
	If(ReadInt(BaseFile) <> $00565350) Then Throw "File is not a .PSV file or has been already stripped!"
	SeekStream(BaseFile, 0) 'Reset the seek position to 0
	
	'Begin writing the header file
	Print "Begin writing of '" + ExportPath + ".psve'..."
	WriteString(PSV_Meta, "PSVE")
	WriteByte(PSV_Meta, 0) 'Version 0
	WriteByte(PSV_Meta, 0) 'License count, we don't know this yet
	
	Print "Begin writing of '" + ExportPath + ".hdr'..."
	Local PSV_HDR:TStream = WriteStream(ExportPath + ".hdr")
	If Not(PSV_HDR) Then Throw "Failed to write '" + ExportPath + ".hdr" + "'."

	CopyBytes(BaseFile, PSV_Meta, $200)
	SeekStream(BaseFile, 0) 'Reset the seek position to 0
	CopyBytes(BaseFile, PSV_HDR, $200)
	CloseFile(PSV_HDR)
	
	'Copy everything between $200 - $1E00
	For Local x = $200 To $1E00 - 1
		WriteByte(ExportFile, ReadByte(BaseFile))
	Next
	
	Print "Begin writing of '" + ExportPath + ".unk'..."
	Local PSV_UNK:TStream = WriteStream(ExportPath + ".unk")
	If Not(PSV_UNK) Then Throw "Failed to write '" + ExportPath + ".unk" + "'."
	'Now we seek to $1E00, write these bytes as blank in the real deal
	For Local x = 0 To $260 - 1
		WriteByte(ExportFile, 0)
		Local PSV_CurrentByte:Byte = ReadByte(BaseFile)
		WriteByte(PSV_Meta, PSV_CurrentByte) 'And also export it to the header file	
		WriteByte(PSV_UNK, PSV_CurrentByte)
	Next
	CloseFile(PSV_UNK)
	Local LicenseBuffer:TBank = CreateBank(ChunkSize)
	Local LicenseBufferStr:TStream = CreateBankStream(LicenseBuffer)
	Local LicenseBufferChunk:UInt = ChunkSize
	
	'Loop this until end of file is reached
	Print "Begin writing of '" + ExportPath + ".psv'..."
	While Not Eof(BaseFile)
	
		'Copy 4096 bytes instead of one by one, way quicker
		SeekStream(LicenseBufferStr, 0)
		If(StreamSize(BaseFile) - StreamPos(BaseFile) < ChunkSize)
			LicenseBufferChunk = StreamSize(BaseFile) - StreamPos(BaseFile)
			CopyBytes(BaseFile, LicenseBufferStr, LicenseBufferChunk, ChunkSize)
		Else
			CopyBytes(BaseFile, LicenseBufferStr, ChunkSize, ChunkSize)
		EndIf
		SeekStream(LicenseBufferStr, 0)
		
		'Scan for license header in the loaded chunk
		For Local TMP_X = 0 To LicenseBufferChunk - 1
			'A result was FOUND
			If(PSV_SearchPos = Len(PSV_SearchHeader))
				Local LicenseOffset:UInt = UInt(StreamPos(BaseFile) - LicenseBufferChunk + TMP_X - Len(PSV_SearchHeader))
				Print("License data detected at address $" + Hex(LicenseOffset))
				
				LicenseArray = LicenseArray[..(Len(LicenseArray) + 1)]
				LicenseArray[LicenseCount] = LicenseOffset
				LicenseCount = LicenseCount + 1
			EndIf
		
			'Did one of the bytes match the search array?
			If(PeekByte(LicenseBuffer, TMP_X) = PSV_SearchHeader[PSV_SearchPos])
				PSV_SearchPos = PSV_SearchPos + 1
			Else 'Oh, then reset the search position
				PSV_SearchPos = 0
			EndIf

		Next
		
		'Copy scanned memory bank bytes into the exported file
		CopyBytes(LicenseBufferStr, ExportFile, LicenseBufferChunk)

		'Progress
		If(MilliSecs() > Timer + UpdateRate)
			Print "Copying (" + Left(Float(StreamPos(BaseFile)) / Float(StreamSize(BaseFile)) * 100, 4) + "% - " + StreamPos(BaseFile) + "/" + StreamSize(BaseFile) + ")"
			Timer = MilliSecs()
		EndIf
	Wend
	CloseStream(LicenseBufferStr)
	
	Print "Found a license count total of: " + LicenseCount
	
	'For EachIn LicenseCount
	For Local TMP_X = 0 To LicenseCount - 1
		Local LicenseOffset:UInt = LicenseArray[TMP_X]
		
		'LIC1 Patching
		Print "Exporting LIC1 Data to '" + ExportPath + "_" + Hex(LicenseOffset) + ".lic1'..."
		SeekStream(BaseFile, LicenseOffset + $40 + Len(PSV_SearchHeader))
		SeekStream(ExportFile, LicenseOffset - $200 + $40 + Len(PSV_SearchHeader))
		Local PSV_LIC1:TStream = WriteStream(ExportPath + "_" + Hex(LicenseOffset) + ".lic1")
		WriteInt(PSV_Meta, LicenseOffset) 'Note the offset for the LIC
		'WriteLong(PSV_Meta, LicenseOffset) 'Note the offset for the LIC
		For Local TMP_Y = 0 To $10 - 1
			Local PSV_CurrentByte:Byte = ReadByte(BaseFile)
			WriteByte(PSV_Meta, PSV_CurrentByte)
			WriteByte(PSV_LIC1, PSV_CurrentByte)
			WriteByte(ExportFile, 0)
		Next
		CloseFile(PSV_LIC1)
		
		'LIC2 Patching
		Print "Exporting LIC2 Data to '" + ExportPath + "_" + Hex(LicenseOffset) + ".lic2'..."
		SeekStream(BaseFile, LicenseOffset + $40 + $10 + $40 + Len(PSV_SearchHeader))
		SeekStream(ExportFile, LicenseOffset - $200 + $40 + $10 + $40 + Len(PSV_SearchHeader))
		Local PSV_LIC2:TStream = WriteStream(ExportPath + "_" + Hex(LicenseOffset) + ".lic2")
		
		For Local TMP_Y = 0 To $160 - 1
			Local PSV_CurrentByte:Byte = ReadByte(BaseFile)
			WriteByte(PSV_Meta, PSV_CurrentByte)
			WriteByte(PSV_LIC2, PSV_CurrentByte)
			WriteByte(ExportFile, 0)
		Next
		CloseFile(PSV_LIC2)
		
	Next
	
	
	'Update the license count in the header
	SeekStream(PSV_Meta, 5) 'First 4 is the PSVH, then version, then license count (usually 1)
	WriteByte(PSV_Meta, LicenseCount)
	
	CloseStream(BaseFile)
	CloseStream(ExportFile)
	CloseStream(PSV_Meta)
End Function

Function ExportBulk(SourcePath:String, ExportPath:String)
	If(Lower(SourcePath) = Lower(ExportPath)) Then Throw "Export path is the same as the input path!"
	'Open directory
	Print "Opening directory '" + SourcePath + "'."
	Global Directory:Byte Ptr = ReadDir(SourcePath)
	CreateDir(ExportPath)
	If Not(Directory)
		RuntimeError("Folder '" + SourcePath + "' doesn't exist!")
	EndIf
	
	Repeat
		Local TMP_CurrentFile:String = NextFile(Directory)
		'Finished
		If(TMP_CurrentFile:String = "") 
			Exit
		ElseIf Not(TMP_CurrentFile:String = "." Or TMP_CurrentFile:String = "..")
			'File type match
			If(Right(Lower(TMP_CurrentFile), 4) = ".psv")
				Local TMP_SRC:String = StripDoubleSlashes(SourcePath + "\" + Left(TMP_CurrentFile, Len(TMP_CurrentFile) - 4))
				Local TMP_SRCEX:String = StripDoubleSlashes(ExportPath + "\" + Left(TMP_CurrentFile, Len(TMP_CurrentFile) - 4))
				
				'Catch any exceptions
				Try
					ExportPSV(TMP_SRC, TMP_SRCEX)
				Catch ex:Object
					Print "EXCEPTION!: " + ex.toString
				End Try
			EndIf
		EndIf
	Forever
	CloseDir(Directory)
End Function

Function PatchPSVE(FilePath:String, ExportPath:String, PSVEPath:String)
	If(Lower(FilePath) = Lower(ExportPath)) Then Throw "Export path is the same as the input path!"
	Local PSVE:TStream = ReadFile(PSVEPath)
	If Not(PSVE) Then Throw "Failed to read '" + PSVEPath + "'."
	Local SourcePSV:TStream = ReadFile(FilePath)
	If Not(SourcePSV) Then Throw "Failed to read '" + FilePath + "'."
	Local ExportPSV:TStream = WriteFile(ExportPath)
	If Not(ExportPSV) Then Throw "Failed to write '" + ExportPath + "'."
	
	'PSVE
	If(UInt(ReadInt(PSVE)) = $50535648) Then Throw "'" + PSVEPath + "' isn't a valid PSVE file!"
	'Version
	If(ReadByte(PSVE) <> $00) Then Throw "'" + PSVEPath + "' uses a different version of the format!"
	'License Count
	Local LicenseCount:Byte = ReadByte(PSVE)
	
	'Safety check so PSVE seeking doesn't underflow/overflow
	If(StreamSize(PSVE) <> (LicenseCount * $174) + $200 + $260 + $6) Then Throw "PSVE filesize mismatch!"
	
	'Header
	Print "Stitching Header..."
	CopyBytes(PSVE, ExportPSV, $200)
	
	'In between stuff
	CopyBytes(SourcePSV, ExportPSV, $1C00)
	
	Print "Stitching UNK..."
	'Unk
	CopyBytes(PSVE, ExportPSV, $260)
	
	'Skip to the part after the UNK and copy the rest of the file
	SeekStream(SourcePSV, $1E60)
	'CopyBytes(PSVE, ExportPSV, StreamSize(SourcePSV) - $1E00, ChunkSize)
	Local LicenseBufferChunk:UInt = ChunkSize
	Local Timer:UInt = MilliSecs() ' Updates every second
	While Not Eof(SourcePSV)
		If(StreamSize(SourcePSV) - StreamPos(SourcePSV) < ChunkSize)
			LicenseBufferChunk = StreamSize(SourcePSV) - StreamPos(SourcePSV)
			CopyBytes(SourcePSV, ExportPSV, LicenseBufferChunk, ChunkSize)
		Else
			CopyBytes(SourcePSV, ExportPSV, ChunkSize, ChunkSize)
		EndIf
		'Progress
		If(MilliSecs() > Timer + UpdateRate)
			Print "Copying (" + Left(Float(StreamPos(SourcePSV)) / Float(StreamSize(SourcePSV)) * 100, 4) + "% - " + StreamPos(SourcePSV) + "/" + StreamSize(SourcePSV) + ")"
			Timer = MilliSecs()
		EndIf
	Wend
	
	For Local x = 1 To LicenseCount
		'LIC1
		Local LicenseOffset:UInt = ReadInt(PSVE)
		Print "Injecting License " + x + " of " + LicenseCount + " at offset: " + Hex(LicenseOffset)
		Print "Injecting LIC1"
		SeekStream(ExportPSV, LicenseOffset + $50)
		CopyBytes(PSVE, ExportPSV, $10)
		
		'LIC2
		Print "Injecting LIC2"
		SeekStream(ExportPSV, LicenseOffset + $A0)
		CopyBytes(PSVE, ExportPSV, $160)
	
	Next
	
	CloseFile(PSVE)
	CloseFile(SourcePSV)
	CloseFile(ExportPSV)
End Function
