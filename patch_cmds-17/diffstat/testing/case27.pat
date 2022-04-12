From bunk@kernel.org Fri Aug 24 01:11:51 2007
From: Adrian Bunk <bunk@kernel.org>
To: Andrew Morton <akpm@linux-foundation.org>,
	Ram Pai <linuxram@us.ibm.com>, Sam Ravnborg <sam@ravnborg.org>
Cc: linux-kernel@vger.kernel.org
Subject: [2.6 patch] fix export_report.pl
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8
Content-Disposition: inline
X-Mutt-Fcc: =sent-mail
Status: RO
Content-Length: 466
Lines: 22

This patch fixes an annoying bug of export_report.pl missing the usages 
of some exports.

Signed-off-by: Adrian Bunk <bunk@kernel.org>

---

This patch has been sent on:
- 14 Aug 2007

--- a/scripts/export_report.pl
+++ b/scripts/export_report.pl
@@ -112,7 +112,7 @@ foreach my $thismod (@allcfiles) {
 			next;
 		}
 		if ($state eq 2) {
-			if ( $_ !~ /0x[0-9a-f]{7,8},/ ) {
+			if ( $_ !~ /0x[0-9a-f]+,/ ) {
 				next;
 			}
 			my $sym = (split /([,"])/,)[4];


From bunk@kernel.org Fri Aug 24 01:13:29 2007
From: Adrian Bunk <bunk@kernel.org>
To: Andrew Morton <akpm@linux-foundation.org>,
	Ram Pai <linuxram@us.ibm.com>, Sam Ravnborg <sam@ravnborg.org>
Cc: linux-kernel@vger.kernel.org
Subject: [2.6 patch] call export_report from the Makefile
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8
Content-Disposition: inline
X-Mutt-Fcc: =sent-mail
Status: RO
Content-Length: 827
Lines: 31

The main feature is that export_report now automatically works
for O= builds.

Signed-off-by: Adrian Bunk <bunk@kernel.org>

---

This patch has been sent on:
- 14 Aug 2007

--- a/Makefile
+++ b/Makefile
@@ -1153,6 +1153,7 @@ help:
 	@echo  'Static analysers'
 	@echo  '  checkstack      - Generate a list of stack hogs'
 	@echo  '  namespacecheck  - Name space analysis on compiled kernel'
+	@echo  '  export_report   - List the usages of all exported symbols'
 	@if [ -r $(srctree)/include/asm-$(ARCH)/Kbuild ]; then \
 	 echo  '  headers_check   - Sanity check on exported headers'; \
 	 fi
@@ -1412,6 +1413,9 @@ versioncheck:
 namespacecheck:
 	$(PERL) $(srctree)/scripts/namespace.pl
 
+export_report:
+	$(PERL) $(srctree)/scripts/export_report.pl
+
 endif #ifeq ($(config-targets),1)
 endif #ifeq ($(mixed-targets),1)
 


From bunk@kernel.org Fri Aug 24 04:43:31 2007
From: Adrian Bunk <bunk@kernel.org>
To: Samuel Thibault <samuel.thibault@ens-lyon.org>,
	Andrew Morton <akpm@linux-foundation.org>,
	linux-input@atrey.karlin.mff.cuni.cz, linux-kernel@vger.kernel.org,
	dtor@mail.ru, Jiri Kosina <jkosina@suse.cz>
Subject: Re: [PATCH] Console keyboard events and accessibility
References: <20070821005718.GD3658@interface.famille.thibault.fr> <20070821130233.58faaa8a.akpm@linux-foundation.org> <20070821202251.GB3658@interface.famille.thibault.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8
Content-Disposition: inline
Content-Transfer-Encoding: 8bit
In-Reply-To: <20070821202251.GB3658@interface.famille.thibault.fr>
X-Mutt-References: <20070821202251.GB3658@interface.famille.thibault.fr>
X-Mutt-Fcc: =sent-mail
Status: RO
Content-Length: 2121
Lines: 57

On Tue, Aug 21, 2007 at 10:22:51PM +0200, Samuel Thibault wrote:
> Hi,
> 
> Andrew Morton, le Tue 21 Aug 2007 13:02:33 -0700, a écrit :
> > On Tue, 21 Aug 2007 02:57:18 +0200
> > Samuel Thibault <samuel.thibault@ens-lyon.org> wrote:
> > 
> > > Some external modules like Speakup need to use the PC keyboard to control
> > > them and also need to get keyboard feedback (caps lock status, etc.)
> > > 
> > > This adds a keyboard notifier that such modules can use to get the keyboard
> > > events and possibly eat them, at several stages:
> > 
> > Adding hooks for non-merged modules is considered sinful.  Making these new
> > exports EXPORT_SYMBOL_GPL might ease the pain.
> 
> That should be fine.
> 
> I'll soon propose a notifier for the console writes too, same story.
> 
> > Is there any prospect of getting at least one of these "external modules
> > like Speakup" merged into mainline?
> 
> I'm working on it.  The problem is that the current code quality is
> still far from mainline requirements (though improving over time).  This
> hook (and the other one I'll post) is a step toward merging.  If these
> hooks can go mainline, then great, that will make life easier for the
> few distributions that want to provide speakup as modules. 

How long does it take you for getting the first users submitted for 
review? If you are working on it it should be in the order of "a few 
months", and earlier merging would anyway gain you only one or two 
kernel releases.

> If they
> remain in -mm for some time and people don't complain, well that's good
> too: at least we know how speakup may hook into the kernel when it gets
> merged.
>...

Without any users it's dead code noone uses, and complaints will most 
likely not occur until you submit the first users for review...

> Samuel

cu
Adrian

BTW: Are these the speakup patches that were in -ac five years ago?

-- 

       "Is there not promise of rain?" Ling Tan asked suddenly out
        of the darkness. There had been need of rain for many days.
       "Only a promise," Lao Er said.
                                       Pearl S. Buck - Dragon Seed


From bunk@kernel.org Fri Aug 24 04:50:47 2007
From: Adrian Bunk <bunk@kernel.org>
To: Andrew Morton <akpm@linux-foundation.org>,
	Adam Belay <abelay@novell.com>,
	Venkatesh Pallipadi <venkatesh.pallipadi@intel.com>,
	Shaohua Li <shaohua.li@intel.com>
Cc: linux-kernel@vger.kernel.org, linux-acpi@vger.kernel.org
Subject: [-mm patch] make "struct menu_governor" static (again)
References: <20070822020648.5ea3a612.akpm@linux-foundation.org>
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8
Content-Disposition: inline
In-Reply-To: <20070822020648.5ea3a612.akpm@linux-foundation.org>
X-Mutt-References: <20070822020648.5ea3a612.akpm@linux-foundation.org>
X-Mutt-Fcc: =sent-mail
Status: RO
Content-Length: 740
Lines: 29

On Wed, Aug 22, 2007 at 02:06:48AM -0700, Andrew Morton wrote:
>...
> Changes since 2.6.23-rc2-mm2:
>...
>  git-acpi.patch
>...
>  git trees
>...

"struct menu_governor" needlessly again became global.

Signed-off-by: Adrian Bunk <bunk@kernel.org>

---
cb33b296204127cf50df54b84b2d79e152fb924b 
diff --git a/drivers/cpuidle/governors/menu.c b/drivers/cpuidle/governors/menu.c
index f5a8865..8d3fdc5 100644
--- a/drivers/cpuidle/governors/menu.c
+++ b/drivers/cpuidle/governors/menu.c
@@ -117,7 +117,7 @@ static int menu_enable_device(struct cpuidle_device *dev)
 	return 0;
 }
 
-struct cpuidle_governor menu_governor = {
+static struct cpuidle_governor menu_governor = {
 	.name =		"menu",
 	.rating =	20,
 	.enable =	menu_enable_device,


From bunk@kernel.org Fri Aug 24 05:01:58 2007
From: Adrian Bunk <bunk@kernel.org>
To: Andrew Morton <akpm@linux-foundation.org>,
	"Eric W. Biederman" <ebiederm@xmission.com>
Cc: linux-kernel@vger.kernel.org
Subject: [-mm patch] remove parport_device_num()
References: <20070822020648.5ea3a612.akpm@linux-foundation.org>
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8
Content-Disposition: inline
In-Reply-To: <20070822020648.5ea3a612.akpm@linux-foundation.org>
X-Mutt-References: <20070822020648.5ea3a612.akpm@linux-foundation.org>
X-Mutt-Fcc: =sent-mail
Status: RO
Content-Length: 3917
Lines: 135

On Wed, Aug 22, 2007 at 02:06:48AM -0700, Andrew Morton wrote:
>...
> Changes since 2.6.23-rc2-mm2:
>...
> +sysctl-parport-remove-binary-paths.patch
>...
>  More sysctl work
>...

parport_device_num() is no longer used.

Signed-off-by: Adrian Bunk <bunk@kernel.org>

---

 Documentation/parport-lowlevel.txt |   29 +++--------------------------
 drivers/parport/daisy.c            |   29 -----------------------------
 include/linux/parport.h            |    1 -
 3 files changed, 3 insertions(+), 56 deletions(-)

0066510df2b5d4972cfd6a4450af8b82c763adfd 
diff --git a/Documentation/parport-lowlevel.txt b/Documentation/parport-lowlevel.txt
index 8f23024..265fcdc 100644
--- a/Documentation/parport-lowlevel.txt
+++ b/Documentation/parport-lowlevel.txt
@@ -25,7 +25,6 @@ Global functions:
   parport_open
   parport_close
   parport_device_id
-  parport_device_num
   parport_device_coords
   parport_find_class
   parport_find_device
@@ -735,7 +734,7 @@ NULL is returned.
 
 SEE ALSO
 
-parport_register_device, parport_device_num
+parport_register_device
 
 parport_close - unregister device for particular device number
 -------------
@@ -787,29 +786,7 @@ Many devices have ill-formed IEEE 1284 Device IDs.
 
 SEE ALSO
 
-parport_find_class, parport_find_device, parport_device_num
-
-parport_device_num - convert device coordinates to device number
-------------------
-
-SYNOPSIS
-
-#include <linux/parport.h>
-
-int parport_device_num (int parport, int mux, int daisy);
-
-DESCRIPTION
-
-Convert between device coordinates (port, multiplexor, daisy chain
-address) and device number (zero-based).
-
-RETURN VALUE
-
-Device number, or -1 if no device at given coordinates.
-
-SEE ALSO
-
-parport_device_coords, parport_open, parport_device_id
+parport_find_class, parport_find_device
 
 parport_device_coords - convert device number to device coordinates
 ------------------
@@ -833,7 +810,7 @@ Zero on success, in which case the coordinates are (*parport, *mux,
 
 SEE ALSO
 
-parport_device_num, parport_open, parport_device_id
+parport_open, parport_device_id
 
 parport_find_class - find a device by its class
 ------------------
diff --git a/drivers/parport/daisy.c b/drivers/parport/daisy.c
index ff9f344..5bbff20 100644
--- a/drivers/parport/daisy.c
+++ b/drivers/parport/daisy.c
@@ -275,35 +275,6 @@ void parport_close(struct pardevice *dev)
 	parport_unregister_device(dev);
 }
 
-/**
- *	parport_device_num - convert device coordinates
- *	@parport: parallel port number
- *	@mux: multiplexor port number (-1 for no multiplexor)
- *	@daisy: daisy chain address (-1 for no daisy chain address)
- *
- *	This tries to locate a device on the given parallel port,
- *	multiplexor port and daisy chain address, and returns its
- *	device number or %-ENXIO if no device with those coordinates
- *	exists.
- **/
-
-int parport_device_num(int parport, int mux, int daisy)
-{
-	int res = -ENXIO;
-	struct daisydev *dev;
-
-	spin_lock(&topology_lock);
-	dev = topology;
-	while (dev && dev->port->portnum != parport &&
-	       dev->port->muxport != mux && dev->daisy != daisy)
-		dev = dev->next;
-	if (dev)
-		res = dev->devnum;
-	spin_unlock(&topology_lock);
-
-	return res;
-}
-
 /* Send a daisy-chain-style CPP command packet. */
 static int cpp_daisy(struct parport *port, int cmd)
 {
diff --git a/include/linux/parport.h b/include/linux/parport.h
index 9cdd694..ec3f765 100644
--- a/include/linux/parport.h
+++ b/include/linux/parport.h
@@ -510,7 +510,6 @@ extern struct pardevice *parport_open (int devnum, const char *name,
 				       int flags, void *handle);
 extern void parport_close (struct pardevice *dev);
 extern ssize_t parport_device_id (int devnum, char *buffer, size_t len);
-extern int parport_device_num (int parport, int mux, int daisy);
 extern void parport_daisy_deselect_all (struct parport *port);
 extern int parport_daisy_select (struct parport *port, int daisy, int mode);
 


From bunk@kernel.org Fri Aug 24 05:07:37 2007
From: Adrian Bunk <bunk@kernel.org>
To: Andrew Morton <akpm@linux-foundation.org>,
	Chris Wright <chrisw@sous-sol.org>
Cc: linux-kernel@vger.kernel.org
Subject: [-mm patch] make do_restart_poll() static
References: <20070822020648.5ea3a612.akpm@linux-foundation.org>
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8
Content-Disposition: inline
In-Reply-To: <20070822020648.5ea3a612.akpm@linux-foundation.org>
X-Mutt-References: <20070822020648.5ea3a612.akpm@linux-foundation.org>
X-Mutt-Fcc: =sent-mail
Status: RO
Content-Length: 728
Lines: 29

On Wed, Aug 22, 2007 at 02:06:48AM -0700, Andrew Morton wrote:
>...
> Changes since 2.6.23-rc2-mm2:
>...
> +use-erestart_restartblock-if-poll-is-interrupted-by-a-signal.patch
>...
>  The infamous misc
>...

do_restart_poll() can become static.

Signed-off-by: Adrian Bunk <bunk@kernel.org>

---
59cd2d11f5f0189973bb280c59262eb50984cb88 
diff --git a/fs/select.c b/fs/select.c
index 5a3ab01..3e515aa 100644
--- a/fs/select.c
+++ b/fs/select.c
@@ -711,7 +711,7 @@ out_fds:
 	return err;
 }
 
-long do_restart_poll(struct restart_block *restart_block)
+static long do_restart_poll(struct restart_block *restart_block)
 {
 	struct pollfd __user *ufds = (struct pollfd __user*)restart_block->arg0;
 	int nfds = restart_block->arg1;


