Index: allowev.c
*** /build/x11r6/XFree86-960317/xc/programs/Xserver/Xi/allowev.c	Sun Mar 17 20:08:01 1996
--- /build/x11r6/XFree86-current/xc/programs/Xserver/Xi/allowev.c	Wed Mar 20 20:47:09 1996
***************
*** 63,72 ****
  
  #include "extnsionst.h"
  #include "extinit.h"			/* LookupDeviceIntRec */
  
! extern	int 		IReqCode;
! extern	int 		BadDevice;
! extern	void		(* ReplySwapVector[256]) ();
  
  /***********************************************************************
   *
--- 63,71 ----
  
  #include "extnsionst.h"
  #include "extinit.h"			/* LookupDeviceIntRec */
+ #include "exglobals.h"
  
! #include "allowev.h"
  
  /***********************************************************************
   *
***************
*** 99,105 ****
      {
      TimeStamp		time;
      DeviceIntPtr	thisdev;
-     void AllowSome ();
  
      REQUEST(xAllowDeviceEventsReq);
      REQUEST_SIZE_MATCH(xAllowDeviceEventsReq);
--- 98,103 ----
Index: XIstubs.h
*** /dev/null	Sun Jul 17 19:46:18 1994
--- /build/x11r6/XFree86-current/xc/programs/Xserver/include/XIstubs.h	Wed Mar 20 22:08:14 1996
***************
*** 0 ****
--- 1,105 ----
+ /* $XConsortium$ */
+ /* $XFree86$ */
+ 
+ #ifndef XI_STUBS_H
+ #define XI_STUBS_H 1
+ 
+ int
+ ChangePointerDevice (
+ #if NeedFunctionPrototypes
+ 	DeviceIntPtr           /* old_dev */,
+ 	DeviceIntPtr           /* new_dev */,
+ 	unsigned char          /* x */,
+ 	unsigned char          /* y */
+ #endif
+ 	);
+ 
+ int
+ ChangeDeviceControl (
+ #if NeedFunctionPrototypes
+ 	ClientPtr             /* client */,
+ 	DeviceIntPtr          /* dev */,
+ 	xDeviceCtl *          /* control */
+ #endif
+ 	);
+ 
+ #endif /* XI_STUBS_H */
