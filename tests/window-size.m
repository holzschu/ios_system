#import "ios_system.h"
#include <errno.h>
#include <pthread.h>
#include <stdio.h>

static const char first_session[] = "first", second_session[] = "second", unknown_session[] = "unknown";
static int failures;

#define CHECK(condition) do { if (!(condition)) { \
    fprintf(stderr, "FAIL line %d: %s\n", __LINE__, #condition); \
    failures++; \
} } while (0)

static void *read_from_another_thread(void *unused) {
    (void)unused;
    @autoreleasepool {
        int columns = 0, rows = 0;
        CHECK(ios_getWindowSize(&columns, &rows, &first_session) == 0);
        CHECK(columns == 91 && rows == 37);
        CHECK(ios_getWindowSize(&columns, &rows, &second_session) == 0);
        CHECK(columns == 132 && rows == 45);
    }
    return NULL;
}

int main(void) {
    @autoreleasepool {
        int columns = -1, rows = -1;
        CHECK(ios_getWindowSize(&columns, &rows, &unknown_session) == ENOENT);
        CHECK(columns == -1 && rows == -1);
        ios_switchSession(&first_session);
        ios_setWindowSize(91, 37, &first_session);
        ios_switchSession(&second_session);
        ios_setWindowSize(132, 45, &second_session);

        pthread_t reader;
        int status = pthread_create(&reader, NULL, read_from_another_thread, NULL);
        CHECK(status == 0);
        if (status == 0) CHECK(pthread_join(reader, NULL) == 0);

        CHECK(ios_getWindowSize(NULL, &rows, &first_session) == EINVAL);
        CHECK(ios_getWindowSize(&columns, NULL, &first_session) == EINVAL);
        CHECK(ios_getWindowSize(&columns, &rows, NULL) == EINVAL);
        CHECK(columns == -1 && rows == -1);

        ios_setWindowSize(104, 52, &first_session);
        CHECK(ios_getWindowSize(&columns, &rows, &first_session) == 0);
        CHECK(columns == 104 && rows == 52);
        CHECK(ios_getWindowSize(&columns, &rows, &second_session) == 0);
        CHECK(columns == 132 && rows == 45);
        ios_closeSession(&first_session);
        CHECK(ios_getWindowSize(&columns, &rows, &first_session) == ENOENT);
        CHECK(columns == 132 && rows == 45);
        CHECK(ios_getWindowSize(&columns, &rows, &second_session) == 0);
        ios_closeSession(&second_session);
        puts(failures ? "Session window size: FAIL" : "Session window size: PASS");
    }
    return failures ? 1 : 0;
}
