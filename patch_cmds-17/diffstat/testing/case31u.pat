==== //depot/vendor/freebsd/src/sys/dev/usb/usbdevs#353 (text+ko) - //depot/projects/usb/src/sys/dev/usb/usbdevs#72 (text+ko) ==== content
@@ -1,4 +1,4 @@
-$FreeBSD: src/sys/dev/usb/usbdevs,v 1.421 2009/07/30 18:53:06 weongyo Exp $
+$FreeBSD: src/sys/dev/usb/usbdevs,v 1.420 2009/07/30 00:15:17 alfred Exp $
 /* $NetBSD: usbdevs,v 1.392 2004/12/29 08:38:44 imp Exp $ */
 
 /*-
@@ -861,6 +861,12 @@
 
 /* Apple Computer products */
 product APPLE EXT_KBD		0x020c	Apple Extended USB Keyboard
+product APPLE KBD_TP_ANSI	0x0223	Apple Internal Keyboard/Trackpad (Wellspring/ANSI)
+product APPLE KBD_TP_ISO	0x0224	Apple Internal Keyboard/Trackpad (Wellspring/ISO)
+product APPLE KBD_TP_JIS	0x0225	Apple Internal Keyboard/Trackpad (Wellspring/JIS)
+product APPLE KBD_TP_ANSI2	0x0230	Apple Internal Keyboard/Trackpad (Wellspring2/ANSI)
+product APPLE KBD_TP_ISO2	0x0231	Apple Internal Keyboard/Trackpad (Wellspring2/ISO)
+product APPLE KBD_TP_JIS2	0x0232	Apple Internal Keyboard/Trackpad (Wellspring2/JIS)
 product APPLE OPTMOUSE		0x0302	Optical mouse
 product APPLE MIGHTYMOUSE	0x0304	Mighty Mouse
 product APPLE EXT_KBD_HUB	0x1003	Hub in Apple Extended USB Keyboard
@@ -902,6 +908,7 @@
 product ASUS RT2573_2		0x1724	RT2573
 product ASUS LCM		0x1726	LCM display
 product ASUS P535		0x420f	ASUS P535 PDA
+product	ASUS GMSC		0x422f	ASUS Generic Mass Storage
 
 /* ATen products */
 product ATEN UC1284		0x2001	Parallel printer
@@ -1177,12 +1184,12 @@
 product DLINK DSB650TX3		0x400b	10/100 Ethernet
 product DLINK DSB650TX2		0x4102	10/100 Ethernet
 product DLINK DSB650		0xabc1	10/100 Ethernet
-product DLINK2 DWA120_NF	0x3a0d	DWA-120 (no firmware)
-product DLINK2 DWA120		0x3a0e	DWA-120
 product DLINK2 DWLG122C1	0x3c03	DWL-G122 c1
 product DLINK2 WUA1340		0x3c04	WUA-1340
 product DLINK2 DWA111		0x3c06	DWA-111
 product DLINK2 DWA110		0x3c07	DWA-110
+product DLINK2 DWA120_NF	0x3c0d	DWA-120 (no firmware)
+product DLINK2 DWA120		0x3c0e	DWA-120
 
 /* DMI products */
 product DMI CFSM_RW		0xa109	CF/SM Reader/Writer
@@ -1971,6 +1978,7 @@
 product PHILIPS PCA646VC	0x0303	PCA646VC PC Camera
 product PHILIPS PCVC680K	0x0308	PCVC680K Vesta Pro PC Camera
 product PHILIPS DSS150		0x0471	DSS 150 Digital Speaker System
+product PHILIPS SPE3030CC	0x083a	USB 2.0 External Disk
 product PHILIPS SNU5600		0x1236	SNU5600
 product PHILIPS UM10016		0x1552	ISP 1581 Hi-Speed USB MPEG2 Encoder Reference Kit
 product PHILIPS DIVAUSB		0x1801	DIVA USB mp3 player
