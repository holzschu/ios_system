/* $OpenBSD: uidswap.c,v 1.39 2015/06/24 01:49:19 dtucker Exp $ */
/*
 * Author: Tatu Ylonen <ylo@cs.hut.fi>
 * Copyright (c) 1995 Tatu Ylonen <ylo@cs.hut.fi>, Espoo, Finland
 *                    All rights reserved
 * Code for uid-swapping.
 *
 * As far as I am concerned, the code I have written for this software
 * can be used freely for any purpose.  Any derived versions of this
 * software must be clearly marked as such, and if the derived work is
 * incompatible with the protocol description in the RFC file, it must be
 * called by a name other than "ssh" or "Secure Shell".
 */

#include "includes.h"

#include <errno.h>
#include <pwd.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>
#include <stdarg.h>
#include <stdlib.h>

#include <grp.h>

#include "log.h"
#include "uidswap.h"
#include "xmalloc.h"
#include "ios_error.h"

/*
 * Note: all these functions must work in all of the following cases:
 *    1. euid=0, ruid=0
 *    2. euid=0, ruid!=0
 *    3. euid!=0, ruid!=0
 * Additionally, they must work regardless of whether the system has
 * POSIX saved uids or not.
 */

#if defined(_POSIX_SAVED_IDS) && !defined(BROKEN_SAVED_UIDS)
/* Lets assume that posix saved ids also work with seteuid, even though that
   is not part of the posix specification. */
#define SAVED_IDS_WORK_WITH_SETEUID
/* Saved effective uid. */
static uid_t 	saved_euid = 0;
static gid_t	saved_egid = 0;
#endif

/* Saved effective uid. */
static int	privileged = 0;
static int	temporarily_use_uid_effective = 0;
static gid_t	*saved_egroups = NULL, *user_groups = NULL;
static int	saved_egroupslen = -1, user_groupslen = -1;

/*
 * Temporarily changes to the given uid.  If the effective user
 * id is not root, this does nothing.  This call cannot be nested.
 */
void
temporarily_use_uid(struct passwd *pw)
{
	/* Save the current euid, and egroups. */
#ifdef SAVED_IDS_WORK_WITH_SETEUID
	saved_euid = geteuid();
	saved_egid = getegid();
	debug("temporarily_use_uid: %u/%u (e=%u/%u)",
	    (u_int)pw->pw_uid, (u_int)pw->pw_gid,
	    (u_int)saved_euid, (u_int)saved_egid);
#ifndef HAVE_CYGWIN
	if (saved_euid != 0) {
		privileged = 0;
		return;
	}
#endif
#else
	if (geteuid() != 0) {
		privileged = 0;
		return;
	}
#endif /* SAVED_IDS_WORK_WITH_SETEUID */

	privileged = 1;
	temporarily_use_uid_effective = 1;

	saved_egroupslen = getgroups(0, NULL);
    if (saved_egroupslen < 0) {
		fprintf(thread_stderr, "getgroups: %.100s", strerror(errno));
        pthread_exit(NULL);
    }
	if (saved_egroupslen > 0) {
		saved_egroups = xreallocarray(saved_egroups,
		    saved_egroupslen, sizeof(gid_t));
        if (getgroups(saved_egroupslen, saved_egroups) < 0) {
            fprintf(thread_stderr, "getgroups: %.100s", strerror(errno));
            pthread_exit(NULL);
        }
} else { /* saved_egroupslen == 0 */
		free(saved_egroups);
	}

	/* set and save the user's groups */
	if (user_groupslen == -1) {
        if (initgroups(pw->pw_name, pw->pw_gid) < 0) {
            fprintf(thread_stderr, "initgroups: %s: %.100s", pw->pw_name,
                    strerror(errno));
            pthread_exit(NULL);
        }

		user_groupslen = getgroups(0, NULL);
        if (user_groupslen < 0) {
            fprintf(thread_stderr, "getgroups: %.100s", strerror(errno));
            pthread_exit(NULL);
        }
        if (user_groupslen > 0) {
			user_groups = xreallocarray(user_groups,
			    user_groupslen, sizeof(gid_t));
            if (getgroups(user_groupslen, user_groups) < 0) {
				fprintf(thread_stderr, "getgroups: %.100s", strerror(errno));
                pthread_exit(NULL);
            }
		} else { /* user_groupslen == 0 */
			free(user_groups);
		}
	}
	/* Set the effective uid to the given (unprivileged) uid. */
    if (setgroups(user_groupslen, user_groups) < 0) {
        fprintf(thread_stderr, "setgroups: %.100s", strerror(errno));
        pthread_exit(NULL);
    }

#ifndef SAVED_IDS_WORK_WITH_SETEUID
	/* Propagate the privileged gid to all of our gids. */
	if (setgid(getegid()) < 0)
		debug("setgid %u: %.100s", (u_int) getegid(), strerror(errno));
	/* Propagate the privileged uid to all of our uids. */
	if (setuid(geteuid()) < 0)
		debug("setuid %u: %.100s", (u_int) geteuid(), strerror(errno));
#endif /* SAVED_IDS_WORK_WITH_SETEUID */
    if (setegid(pw->pw_gid) < 0) {
        fprintf(thread_stderr, "setegid %u: %.100s", (u_int)pw->pw_gid,
                strerror(errno));
        pthread_exit(NULL);
    }

    if (seteuid(pw->pw_uid) == -1) {
        fprintf(thread_stderr, "seteuid %u: %.100s", (u_int)pw->pw_uid,
                strerror(errno));
        pthread_exit(NULL);
    }
}

void
permanently_drop_suid(uid_t uid)
{
#ifndef NO_UID_RESTORATION_TEST
	uid_t old_uid = getuid();
#endif

	debug("permanently_drop_suid: %u", (u_int)uid);
    if (setresuid(uid, uid, uid) < 0) {
		fprintf(thread_stderr, "setresuid %u: %.100s", (u_int)uid, strerror(errno));
        pthread_exit(NULL);
    }

#ifndef NO_UID_RESTORATION_TEST
	/*
	 * Try restoration of UID if changed (test clearing of saved uid).
	 *
	 * Note that we don't do this on Cygwin, or on Solaris-based platforms
	 * where fine-grained privileges are available (the user might be
	 * deliberately allowed the right to setuid back to root).
	 */
	if (old_uid != uid &&
        (setuid(old_uid) != -1 || seteuid(old_uid) != -1)) {
		fprintf(thread_stderr, "%s: was able to restore old [e]uid", __func__);
        pthread_exit(NULL);
    }
#endif

	/* Verify UID drop was successful */
	if (getuid() != uid || geteuid() != uid) {
		fprintf(thread_stderr, "%s: euid incorrect uid:%u euid:%u (should be %u)",
		    __func__, (u_int)getuid(), (u_int)geteuid(), (u_int)uid);
        pthread_exit(NULL);
    }
}

/*
 * Restores to the original (privileged) uid.
 */
void
restore_uid(void)
{
	/* it's a no-op unless privileged */
	if (!privileged) {
		debug("restore_uid: (unprivileged)");
		return;
	}
    if (!temporarily_use_uid_effective) {
        fprintf(thread_stderr, "restore_uid: temporarily_use_uid not effective");
        pthread_exit(NULL);
    }

#ifdef SAVED_IDS_WORK_WITH_SETEUID
	debug("restore_uid: %u/%u", (u_int)saved_euid, (u_int)saved_egid);
    /* Set the effective uid back to the saved privileged uid. */
    if (seteuid(saved_euid) < 0) {
        fprintf(thread_stderr, "seteuid %u: %.100s", (u_int)saved_euid, strerror(errno));
        pthread_exit(NULL);
    }
    if (setegid(saved_egid) < 0) {
        fprintf(thread_stderr, "setegid %u: %.100s", (u_int)saved_egid, strerror(errno));
        pthread_exit(NULL);
    }
#else /* SAVED_IDS_WORK_WITH_SETEUID */
	/*
	 * We are unable to restore the real uid to its unprivileged value.
	 * Propagate the real uid (usually more privileged) to effective uid
	 * as well.
	 */
	setuid(getuid());
	setgid(getgid());
#endif /* SAVED_IDS_WORK_WITH_SETEUID */

    if (setgroups(saved_egroupslen, saved_egroups) < 0) {
        fprintf(thread_stderr, "setgroups: %.100s", strerror(errno));
        pthread_exit(NULL);
    }
    temporarily_use_uid_effective = 0;
}

/*
 * Permanently sets all uids to the given uid.  This cannot be
 * called while temporarily_use_uid is effective.
 */
void
permanently_set_uid(struct passwd *pw)
{
#ifndef NO_UID_RESTORATION_TEST
	uid_t old_uid = getuid();
	gid_t old_gid = getgid();
#endif

    if (pw == NULL) {
        fprintf(thread_stderr, "permanently_set_uid: no user given");
        pthread_exit(NULL);
    }
    if (temporarily_use_uid_effective) {
        fprintf(thread_stderr, "permanently_set_uid: temporarily_use_uid effective");
        pthread_exit(NULL);
    }
    debug("permanently_set_uid: %u/%u", (u_int)pw->pw_uid,
          (u_int)pw->pw_gid);

    if (setresgid(pw->pw_gid, pw->pw_gid, pw->pw_gid) < 0) {
        fprintf(thread_stderr, "setresgid %u: %.100s", (u_int)pw->pw_gid, strerror(errno));
        pthread_exit(NULL);
    }

#ifdef __APPLE__
	/*
	 * OS X requires initgroups after setgid to opt back into
	 * memberd support for >16 supplemental groups.
	 */
    if (initgroups(pw->pw_name, pw->pw_gid) < 0) {
        fprintf(thread_stderr, "initgroups %.100s %u: %.100s",
                pw->pw_name, (u_int)pw->pw_gid, strerror(errno));
        pthread_exit(NULL);
    }
#endif

    if (setresuid(pw->pw_uid, pw->pw_uid, pw->pw_uid) < 0) {
        fprintf(thread_stderr, "setresuid %u: %.100s", (u_int)pw->pw_uid, strerror(errno));
        pthread_exit(NULL);
    }

#ifndef NO_UID_RESTORATION_TEST
	/* Try restoration of GID if changed (test clearing of saved gid) */
    if (old_gid != pw->pw_gid && pw->pw_uid != 0 &&
        (setgid(old_gid) != -1 || setegid(old_gid) != -1)) {
        fprintf(thread_stderr, "%s: was able to restore old [e]gid", __func__);
        pthread_exit(NULL);
    }
#endif

	/* Verify GID drop was successful */
	if (getgid() != pw->pw_gid || getegid() != pw->pw_gid) {
		fprintf(thread_stderr, "%s: egid incorrect gid:%u egid:%u (should be %u)",
		    __func__, (u_int)getgid(), (u_int)getegid(),
		    (u_int)pw->pw_gid);
        pthread_exit(NULL);
    }

#ifndef NO_UID_RESTORATION_TEST
	/* Try restoration of UID if changed (test clearing of saved uid) */
	if (old_uid != pw->pw_uid &&
        (setuid(old_uid) != -1 || seteuid(old_uid) != -1)) {
        fprintf(thread_stderr, "%s: was able to restore old [e]uid", __func__);
        pthread_exit(NULL);
    }
#endif

	/* Verify UID drop was successful */
	if (getuid() != pw->pw_uid || geteuid() != pw->pw_uid) {
		fprintf(thread_stderr, "%s: euid incorrect uid:%u euid:%u (should be %u)",
		    __func__, (u_int)getuid(), (u_int)geteuid(),
		    (u_int)pw->pw_uid);
        pthread_exit(NULL);
    }
}

