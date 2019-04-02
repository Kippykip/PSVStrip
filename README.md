



# PSVStrip
PSVStrip v0.1 - http://kippykip.com

**Description:**
   This is a small tool to strip out the unique license and header data found in PlayStation Vita (.PSV) games dumped with https://github.com/motoharu-gosuto/psvgamesd. 
   Since having multiple copies of the same PSVita game will actually contain slightly different license data, this tool provides a way so that hashes can be compared with other dumps for verification/preservation purposes, or so the unique data can be backed up for personal use in the form of a .PSVE file.

   This program is an attempt to be a replacement for https://github.com/FakeShemp/VitaLicenseEditor

**Arguments:**

>PSVStrip.exe -psvstrip source.psv destination.psv

>PSVStrip.exe -dirstrip sourcedirectory exportdirectory

>PSVStrip.exe -applypsve source.psv destination.psv stripdata.psve

**Argument Definitions:**

	-psvstrip: Strips out license data into external files for checksum purposes. 
	(a new stripped .PSV file, and the export files .HDR/.UNK/.LIC1/.LIC2/.PSVE).
	-dirstrip: Strips out licensing data from multiple .PSV files in a directory (in bulk).
	-applypsve: Re-adds the licensing data and header info back to a stripped .PSV file.
   
**Upcoming**
 - Maybe find a way of adding fake license data, so stripped games are bootable again without the need of a .PSVE file.

**Version History**

    Version 0.1
        - Initial release
## PSVE File Format Specifications

    *HEADER*
    [4 BYTES] PSVE
    [1 BYTE] Format Version Number (Always $00 as of 02/04/2019 DD/MM/YYYY)
    [1 BYTE] Number of Licenses found in .PSV (Almost always $01)
    [512 BYTES] PSVGameSD dump header.
    [608 BYTES] Unique UNK data.
    
    *This part loops by the "Number of Licenses" byte from the above.*
    [4 BYTES / Unsigned INT] License Offset from the original .PSV file.
    [16 BYTES] Unique License #1 data
    [352 BYTES] Unique License #2 data

## Additional Credits and Sources:
**iCEQB**: For explaining in detail on how the stripping process should work, as well as explaining parts of the .PSV format.\
[Discussion thread for No-Intro](http://forums.no-intro.org/viewtopic.php?f=2&t=3443/).
**motoharu-gosuto**: Creator of [psvgamesd](https://github.com/motoharu-gosuto/psvgamesd/).
**FakeShemp**: Creator of [VitaLicenseEditor](https://github.com/FakeShemp/VitaLicenseEditor/).

## Support:
I hope that you find this tool useful!
If you support the work I've put in, and want me to see more of these type of projects, you can support me with donations.  I'd gladly appreciate it! ![OH BOI](https://kippykip.com/styles/sleek/xenforo/smilies/k_dance.gif)  
  
**KO-FI!!!**:  
**http://ko-fi.com/kippykip**
  
**Crypto Addresses**:  
**ETH:** 0xb9D6c74986c5dC372CBA6d1cb8a099910557Ab62  
**LTC:** LYru8N52kX3zTzbsMX5jmxB1bFoMsARUCo  
**BTC:** 18zvRocGqCBfWAVWqJDzf4UNFZUhc93aQ2  
**XLM:** GBUYHTDZWL22SP6OHV5U5WB33KQYFZBY2LMJO3RTUQQS5SUZNQXT322X  
**DASH:** Xg2VSf2Via9whT6K6U6wGkECKACxPBa7MT  
**0x:** 0xb9D6c74986c5dC372CBA6d1cb8a099910557Ab62  
**TRX:** TQbZ6TxdNTJtZ7djJ3R7Sv1gB2DaeA5Bqy
