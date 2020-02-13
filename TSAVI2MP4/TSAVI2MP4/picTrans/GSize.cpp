 
#include "GSize.h"

void GSize::scale(const GSize &s, AspectRatioMode mode)
{
    if (mode == IgnoreAspectRatio || wd == 0 || ht == 0) {
        wd = s.wd;
        ht = s.ht;
    } else {
        bool useHeight;
        int64_t rw = int64_t(s.ht) * int64_t(wd) / int64_t(ht);

        if (mode == KeepAspectRatio) {
            useHeight = (rw <= s.wd);
        } else { // mode == Qt::KeepAspectRatioByExpanding
            useHeight = (rw >= s.wd);
        }

        if (useHeight) {
            wd = int32_t(rw);
            ht = s.ht;
        } else {
            ht = int32_t( int64_t(s.wd) * int64_t(ht) / int64_t(wd));
            wd = s.wd;
        }
    }
}

void GSizeF::scale(const GSizeF &s, AspectRatioMode mode)
{
    if (mode == IgnoreAspectRatio || gIsNull(wd) || gIsNull(ht)) {
        wd = s.wd;
        ht = s.ht;
    } else {
        bool useHeight;
        real_t rw = s.ht * wd / ht;

        if (mode == KeepAspectRatio) {
            useHeight = (rw <= s.wd);
        } else { // mode == Qt::KeepAspectRatioByExpanding
            useHeight = (rw >= s.wd);
        }

        if (useHeight) {
            wd = rw;
            ht = s.ht;
        } else {
            ht = s.wd * ht / wd;
            wd = s.wd;
        }
    }
}
