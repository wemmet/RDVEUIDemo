 
#include "GRect.h"
#include "math.h"

bool GRect::contains(const GPoint &p, bool proper) const
{
    int32_t l, r;
    if (x2 < x1 - 1) {
        l = x2;
        r = x1;
    } else {
        l = x1;
        r = x2;
    }
    if (proper) {
        if (p.x() <= l || p.x() >= r)
            return false;
    } else {
        if (p.x() < l || p.x() > r)
            return false;
    }
    int32_t t, b;
    if (y2 < y1 - 1) {
        t = y2;
        b = y1;
    } else {
        t = y1;
        b = y2;
    }
    if (proper) {
        if (p.y() <= t || p.y() >= b)
            return false;
    } else {
        if (p.y() < t || p.y() > b)
            return false;
    }
    return true;
}

bool GRect::contains(const GRect &r, bool proper) const
{
    if (isNull() || r.isNull())
        return false;

    int32_t l1 = x1;
    int32_t r1 = x1;
    if (x2 - x1 + 1 < 0)
        l1 = x2;
    else
        r1 = x2;

    int32_t l2 = r.x1;
    int32_t r2 = r.x1;
    if (r.x2 - r.x1 + 1 < 0)
        l2 = r.x2;
    else
        r2 = r.x2;

    if (proper) {
        if (l2 <= l1 || r2 >= r1)
            return false;
    } else {
        if (l2 < l1 || r2 > r1)
            return false;
    }

    int32_t t1 = y1;
    int32_t b1 = y1;
    if (y2 - y1 + 1 < 0)
        t1 = y2;
    else
        b1 = y2;

    int32_t t2 = r.y1;
    int32_t b2 = r.y1;
    if (r.y2 - r.y1 + 1 < 0)
        t2 = r.y2;
    else
        b2 = r.y2;

    if (proper) {
        if (t2 <= t1 || b2 >= b1)
            return false;
    } else {
        if (t2 < t1 || b2 > b1)
            return false;
    }

    return true;
}

GRect GRect::operator|(const GRect &r) const
{
    if (isNull())
        return r;
    if (r.isNull())
        return *this;

    int32_t l1 = x1;
    int32_t r1 = x1;
    if (x2 - x1 + 1 < 0)
        l1 = x2;
    else
        r1 = x2;

    int32_t l2 = r.x1;
    int32_t r2 = r.x1;
    if (r.x2 - r.x1 + 1 < 0)
        l2 = r.x2;
    else
        r2 = r.x2;

    int32_t t1 = y1;
    int32_t b1 = y1;
    if (y2 - y1 + 1 < 0)
        t1 = y2;
    else
        b1 = y2;

    int32_t t2 = r.y1;
    int32_t b2 = r.y1;
    if (r.y2 - r.y1 + 1 < 0)
        t2 = r.y2;
    else
        b2 = r.y2;

    GRect tmp;
    tmp.x1 = gMin(l1, l2);
    tmp.x2 = gMax(r1, r2);
    tmp.y1 = gMin(t1, t2);
    tmp.y2 = gMax(b1, b2);
    return tmp;
}

GRect GRect::operator&(const GRect &r) const
{
    if (isNull() || r.isNull())
        return GRect();

    int32_t l1 = x1;
    int32_t r1 = x1;
    if (x2 - x1 + 1 < 0)
        l1 = x2;
    else
        r1 = x2;

    int32_t l2 = r.x1;
    int32_t r2 = r.x1;
    if (r.x2 - r.x1 + 1 < 0)
        l2 = r.x2;
    else
        r2 = r.x2;

    if (l1 > r2 || l2 > r1)
        return GRect();

    int32_t t1 = y1;
    int32_t b1 = y1;
    if (y2 - y1 + 1 < 0)
        t1 = y2;
    else
        b1 = y2;

    int32_t t2 = r.y1;
    int32_t b2 = r.y1;
    if (r.y2 - r.y1 + 1 < 0)
        t2 = r.y2;
    else
        b2 = r.y2;

    if (t1 > b2 || t2 > b1)
        return GRect();

    GRect tmp;
    tmp.x1 = gMax(l1, l2);
    tmp.x2 = gMin(r1, r2);
    tmp.y1 = gMax(t1, t2);
    tmp.y2 = gMin(b1, b2);
    return tmp;
}

bool GRect::intersects(const GRect &r) const
{
    if (isNull() || r.isNull())
        return false;

    int32_t l1 = x1;
    int32_t r1 = x1;
    if (x2 - x1 + 1 < 0)
        l1 = x2;
    else
        r1 = x2;

    int32_t l2 = r.x1;
    int32_t r2 = r.x1;
    if (r.x2 - r.x1 + 1 < 0)
        l2 = r.x2;
    else
        r2 = r.x2;

    if (l1 > r2 || l2 > r1)
        return false;

    int32_t t1 = y1;
    int32_t b1 = y1;
    if (y2 - y1 + 1 < 0)
        t1 = y2;
    else
        b1 = y2;

    int32_t t2 = r.y1;
    int32_t b2 = r.y1;
    if (r.y2 - r.y1 + 1 < 0)
        t2 = r.y2;
    else
        b2 = r.y2;

    if (t1 > b2 || t2 > b1)
        return false;

    return true;
}

GRectF GRectF::normalized() const
{
    GRectF r = *this;
    if (r.w < 0) {
        r.xp += r.w;
        r.w = -r.w;
    }
    if (r.h < 0) {
        r.yp += r.h;
        r.h = -r.h;
    }
    return r;
}


bool GRectF::contains(const GPointF &p) const
{
    real_t l = xp;
    real_t r = xp;
    if (w < 0)
        l += w;
    else
        r += w;
    if (l == r) // null rect
        return false;

    if (p.x() < l || p.x() > r)
        return false;

    real_t t = yp;
    real_t b = yp;
    if (h < 0)
        t += h;
    else
        b += h;
    if (t == b) // null rect
        return false;

    if (p.y() < t || p.y() > b)
        return false;

    return true;
}


bool GRectF::contains(const GRectF &r) const
{
    real_t l1 = xp;
    real_t r1 = xp;
    if (w < 0)
        l1 += w;
    else
        r1 += w;
    if (l1 == r1) // null rect
        return false;

    real_t l2 = r.xp;
    real_t r2 = r.xp;
    if (r.w < 0)
        l2 += r.w;
    else
        r2 += r.w;
    if (l2 == r2) // null rect
        return false;

    if (l2 < l1 || r2 > r1)
        return false;

    real_t t1 = yp;
    real_t b1 = yp;
    if (h < 0)
        t1 += h;
    else
        b1 += h;
    if (t1 == b1) // null rect
        return false;

    real_t t2 = r.yp;
    real_t b2 = r.yp;
    if (r.h < 0)
        t2 += r.h;
    else
        b2 += r.h;
    if (t2 == b2) // null rect
        return false;

    if (t2 < t1 || b2 > b1)
        return false;

    return true;
}


GRectF GRectF::operator|(const GRectF &r) const
{
    if (isNull())
        return r;
    if (r.isNull())
        return *this;

    real_t left = xp;
    real_t right = xp;
    if (w < 0)
        left += w;
    else
        right += w;

    if (r.w < 0) {
        left = gMin(left, r.xp + r.w);
        right = gMax(right, r.xp);
    } else {
        left = gMin(left, r.xp);
        right = gMax(right, r.xp + r.w);
    }

    real_t top = yp;
    real_t bottom = yp;
    if (h < 0)
        top += h;
    else
        bottom += h;

    if (r.h < 0) {
        top = gMin(top, r.yp + r.h);
        bottom = gMax(bottom, r.yp);
    } else {
        top = gMin(top, r.yp);
        bottom = gMax(bottom, r.yp + r.h);
    }

    return GRectF(left, top, right - left, bottom - top);
}

GRectF GRectF::operator&(const GRectF &r) const
{
    real_t l1 = xp;
    real_t r1 = xp;
    if (w < 0)
        l1 += w;
    else
        r1 += w;
    if (l1 == r1) // null rect
        return GRectF();

    real_t l2 = r.xp;
    real_t r2 = r.xp;
    if (r.w < 0)
        l2 += r.w;
    else
        r2 += r.w;
    if (l2 == r2) // null rect
        return GRectF();

    if (l1 >= r2 || l2 >= r1)
        return GRectF();

    real_t t1 = yp;
    real_t b1 = yp;
    if (h < 0)
        t1 += h;
    else
        b1 += h;
    if (t1 == b1) // null rect
        return GRectF();

    real_t t2 = r.yp;
    real_t b2 = r.yp;
    if (r.h < 0)
        t2 += r.h;
    else
        b2 += r.h;
    if (t2 == b2) // null rect
        return GRectF();

    if (t1 >= b2 || t2 >= b1)
        return GRectF();

    GRectF tmp;
    tmp.xp = gMax(l1, l2);
    tmp.yp = gMax(t1, t2);
    tmp.w = gMin(r1, r2) - tmp.xp;
    tmp.h = gMin(b1, b2) - tmp.yp;
    return tmp;
}

bool GRectF::intersects(const GRectF &r) const
{
    real_t l1 = xp;
    real_t r1 = xp;
    if (w < 0)
        l1 += w;
    else
        r1 += w;
    if (l1 == r1) // null rect
        return false;

    real_t l2 = r.xp;
    real_t r2 = r.xp;
    if (r.w < 0)
        l2 += r.w;
    else
        r2 += r.w;
    if (l2 == r2) // null rect
        return false;

    if (l1 >= r2 || l2 >= r1)
        return false;

    real_t t1 = yp;
    real_t b1 = yp;
    if (h < 0)
        t1 += h;
    else
        b1 += h;
    if (t1 == b1) // null rect
        return false;

    real_t t2 = r.yp;
    real_t b2 = r.yp;
    if (r.h < 0)
        t2 += r.h;
    else
        b2 += r.h;
    if (t2 == b2) // null rect
        return false;

    if (t1 >= b2 || t2 >= b1)
        return false;

    return true;
}

GRect GRectF::toAlignedRect() const
{
    int32_t xmin = int32_t(floor(xp));
    int32_t xmax = int32_t(ceil(xp + w));
    int32_t ymin = int32_t(floor(yp));
    int32_t ymax = int32_t(ceil(yp + h));
    return GRect(xmin, ymin, xmax - xmin, ymax - ymin);
}
