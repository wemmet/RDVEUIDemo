#pragma once
#include "GGlobal.h"
#include "GPoint.h"
#include "GSize.h"

class GRect
{
public:
    GRect() { x1 = y1 = 0; x2 = y2 = -1; }
    GRect(const GPoint &topleft, const GPoint &bottomright);
    GRect(const GPoint &topleft, const GSize &size);
    GRect(int32_t left, int32_t top, int32_t width, int32_t height);

	// Null 的 rect 宽和高都为 0
    bool isNull() const;

	//Empty 的 rect 宽或高小于等于 0，可能为负值
    bool isEmpty() const;

	//有效的 rect 宽和高都大于等于 1.
    bool isValid() const;

    int32_t left() const;
    int32_t top() const;
    int32_t right() const;
    int32_t bottom() const;
    GRect normalized() const;

    int32_t x() const;
    int32_t y() const;
    void setLeft(int32_t pos);
    void setTop(int32_t pos);
    void setRight(int32_t pos);
    void setBottom(int32_t pos);
    void setX(int32_t x);
    void setY(int32_t y);

    void setTopLeft(const GPoint &p);
    void setBottomRight(const GPoint &p);
    void setTopRight(const GPoint &p);
    void setBottomLeft(const GPoint &p);

    GPoint topLeft() const;
    GPoint bottomRight() const;
    GPoint topRight() const;
    GPoint bottomLeft() const;
    GPoint center() const;

    void moveLeft(int32_t pos);
    void moveTop(int32_t pos);
    void moveRight(int32_t pos);
    void moveBottom(int32_t pos);
    void moveTopLeft(const GPoint &p);
    void moveBottomRight(const GPoint &p);
    void moveTopRight(const GPoint &p);
    void moveBottomLeft(const GPoint &p);
    void moveCenter(const GPoint &p);

    inline void translate(int32_t dx, int32_t dy);
    inline void translate(const GPoint &p);
    inline GRect translated(int32_t dx, int32_t dy) const;
    inline GRect translated(const GPoint &p) const;

    void moveTo(int32_t x, int32_t t);
    void moveTo(const GPoint &p);

    void setRect(int32_t x, int32_t y, int32_t w, int32_t h);
    inline void getRect(int32_t *x, int32_t *y, int32_t *w, int32_t *h) const;

    void setCoords(int32_t x1, int32_t y1, int32_t x2, int32_t y2);
    inline void getCoords(int32_t *x1, int32_t *y1, int32_t *x2, int32_t *y2) const;

    inline void adjust(int32_t x1, int32_t y1, int32_t x2, int32_t y2);
    inline GRect adjusted(int32_t x1, int32_t y1, int32_t x2, int32_t y2) const;

    GSize size() const;
    int32_t width() const;
    int32_t height() const;
    void setWidth(int32_t w);
    void setHeight(int32_t h);
    void setSize(const GSize &s);

    GRect operator|(const GRect &r) const;
    GRect operator&(const GRect &r) const;
    GRect& operator|=(const GRect &r);
    GRect& operator&=(const GRect &r);

    bool contains(const GPoint &p, bool proper=false) const;
    bool contains(int32_t x, int32_t y) const; // inline methods, _don't_ merge these
    bool contains(int32_t x, int32_t y, bool proper) const;
    bool contains(const GRect &r, bool proper = false) const;
    GRect united(const GRect &other) const;
    GRect intersected(const GRect &other) const;
    bool intersects(const GRect &r) const;

    friend bool operator==(const GRect &, const GRect &);
    friend bool operator!=(const GRect &, const GRect &);


private:
    int32_t x1;
    int32_t y1;
    int32_t x2;
    int32_t y2;
};

bool operator==(const GRect &, const GRect &);
bool operator!=(const GRect &, const GRect &);


inline GRect::GRect(int32_t aleft, int32_t atop, int32_t awidth, int32_t aheight)
{
    x1 = aleft;
    y1 = atop;
    x2 = (aleft + awidth - 1);
    y2 = (atop + aheight - 1);
}

inline GRect::GRect(const GPoint &atopLeft, const GPoint &abottomRight)
{
    x1 = atopLeft.x();
    y1 = atopLeft.y();
    x2 = abottomRight.x();
    y2 = abottomRight.y();
}

inline GRect::GRect(const GPoint &atopLeft, const GSize &asize)
{
    x1 = atopLeft.x();
    y1 = atopLeft.y();
    x2 = (x1+asize.width() - 1);
    y2 = (y1+asize.height() - 1);
}

inline bool GRect::isNull() const
{ return x2 == x1 - 1 && y2 == y1 - 1; }

inline bool GRect::isEmpty() const
{ return x1 > x2 || y1 > y2; }

inline bool GRect::isValid() const
{ return x1 <= x2 && y1 <= y2; }

inline int32_t GRect::left() const
{ return x1; }

inline int32_t GRect::top() const
{ return y1; }

inline int32_t GRect::right() const
{ return x2; }

inline int32_t GRect::bottom() const
{ return y2; }

inline int32_t GRect::x() const
{ return x1; }

inline int32_t GRect::y() const
{ return y1; }

inline void GRect::setLeft(int32_t pos)
{ x1 = pos; }

inline void GRect::setTop(int32_t pos)
{ y1 = pos; }

inline void GRect::setRight(int32_t pos)
{ x2 = pos; }

inline void GRect::setBottom(int32_t pos)
{ y2 = pos; }

inline void GRect::setTopLeft(const GPoint &p)
{ x1 = p.x(); y1 = p.y(); }

inline void GRect::setBottomRight(const GPoint &p)
{ x2 = p.x(); y2 = p.y(); }

inline void GRect::setTopRight(const GPoint &p)
{ x2 = p.x(); y1 = p.y(); }

inline void GRect::setBottomLeft(const GPoint &p)
{ x1 = p.x(); y2 = p.y(); }

inline void GRect::setX(int32_t ax)
{ x1 = ax; }

inline void GRect::setY(int32_t ay)
{ y1 = ay; }

inline GPoint GRect::topLeft() const
{ return GPoint(x1, y1); }

inline GPoint GRect::bottomRight() const
{ return GPoint(x2, y2); }

inline GPoint GRect::topRight() const
{ return GPoint(x2, y1); }

inline GPoint GRect::bottomLeft() const
{ return GPoint(x1, y2); }

inline GPoint GRect::center() const
{ return GPoint((x1+x2)/2, (y1+y2)/2); }

inline int32_t GRect::width() const
{ return  x2 - x1 + 1; }

inline int32_t GRect::height() const
{ return  y2 - y1 + 1; }

inline GSize GRect::size() const
{ return GSize(width(), height()); }

inline void GRect::translate(int32_t dx, int32_t dy)
{
    x1 += dx;
    y1 += dy;
    x2 += dx;
    y2 += dy;
}

inline void GRect::translate(const GPoint &p)
{
    x1 += p.x();
    y1 += p.y();
    x2 += p.x();
    y2 += p.y();
}

inline GRect GRect::translated(int32_t dx, int32_t dy) const
{ return GRect(GPoint(x1 + dx, y1 + dy), GPoint(x2 + dx, y2 + dy)); }

inline GRect GRect::translated(const GPoint &p) const
{ return GRect(GPoint(x1 + p.x(), y1 + p.y()), GPoint(x2 + p.x(), y2 + p.y())); }

inline void GRect::moveTo(int32_t ax, int32_t ay)
{
    x2 += ax - x1;
    y2 += ay - y1;
    x1 = ax;
    y1 = ay;
}

inline void GRect::moveTo(const GPoint &p)
{
    x2 += p.x() - x1;
    y2 += p.y() - y1;
    x1 = p.x();
    y1 = p.y();
}

inline void GRect::moveLeft(int32_t pos)
{ x2 += (pos - x1); x1 = pos; }

inline void GRect::moveTop(int32_t pos)
{ y2 += (pos - y1); y1 = pos; }

inline void GRect::moveRight(int32_t pos)
{
    x1 += (pos - x2);
    x2 = pos;
}

inline void GRect::moveBottom(int32_t pos)
{
    y1 += (pos - y2);
    y2 = pos;
}

inline void GRect::moveTopLeft(const GPoint &p)
{
    moveLeft(p.x());
    moveTop(p.y());
}

inline void GRect::moveBottomRight(const GPoint &p)
{
    moveRight(p.x());
    moveBottom(p.y());
}

inline void GRect::moveTopRight(const GPoint &p)
{
    moveRight(p.x());
    moveTop(p.y());
}

inline void GRect::moveBottomLeft(const GPoint &p)
{
    moveLeft(p.x());
    moveBottom(p.y());
}

inline void GRect::getRect(int32_t *ax, int32_t *ay, int32_t *aw, int32_t *ah) const
{
	if ( ax ) *ax = x1;
	if ( ay ) *ay = y1;
	if ( aw ) *aw = x2 - x1 + 1;
	if ( ah ) *ah = y2 - y1 + 1;
}

inline void GRect::setRect(int32_t ax, int32_t ay, int32_t aw, int32_t ah)
{
    x1 = ax;
    y1 = ay;
    x2 = (ax + aw - 1);
    y2 = (ay + ah - 1);
}

inline void GRect::getCoords(int32_t *xp1, int32_t *yp1, int32_t *xp2, int32_t *yp2) const
{
	if ( xp1 ) *xp1 = x1;
	if ( yp1 ) *yp1 = y1;
	if ( xp2 ) *xp2 = x2;
	if ( yp2 ) *yp2 = y2;
}

inline void GRect::setCoords(int32_t xp1, int32_t yp1, int32_t xp2, int32_t yp2)
{
    x1 = xp1;
    y1 = yp1;
    x2 = xp2;
    y2 = yp2;
}

inline GRect GRect::adjusted(int32_t xp1, int32_t yp1, int32_t xp2, int32_t yp2) const
{ return GRect(GPoint(x1 + xp1, y1 + yp1), GPoint(x2 + xp2, y2 + yp2)); }

inline void GRect::adjust(int32_t dx1, int32_t dy1, int32_t dx2, int32_t dy2)
{
    x1 += dx1;
    y1 += dy1;
    x2 += dx2;
    y2 += dy2;
}

inline void GRect::setWidth(int32_t w)
{ x2 = (x1 + w - 1); }

inline void GRect::setHeight(int32_t h)
{ y2 = (y1 + h - 1); }

inline void GRect::setSize(const GSize &s)
{
    x2 = (s.width()  + x1 - 1);
    y2 = (s.height() + y1 - 1);
}

inline bool GRect::contains(int32_t ax, int32_t ay, bool aproper) const
{
    return contains(GPoint(ax, ay), aproper);
}

inline bool GRect::contains(int32_t ax, int32_t ay) const
{
    return contains(GPoint(ax, ay), false);
}

inline GRect& GRect::operator|=(const GRect &r)
{
    *this = *this | r;
    return *this;
}

inline GRect& GRect::operator&=(const GRect &r)
{
    *this = *this & r;
    return *this;
}

inline GRect GRect::intersected(const GRect &other) const
{
	return *this & other;
}

inline GRect GRect::united(const GRect &r) const
{
    return *this | r;
}

inline bool operator==(const GRect &r1, const GRect &r2)
{
    return r1.x1==r2.x1 && r1.x2==r2.x2 && r1.y1==r2.y1 && r1.y2==r2.y2;
}

inline bool operator!=(const GRect &r1, const GRect &r2)
{
    return r1.x1!=r2.x1 || r1.x2!=r2.x2 || r1.y1!=r2.y1 || r1.y2!=r2.y2;
}

class GRectF
{
public:
    GRectF() { xp = yp = 0.; w = h = 0.; }
    GRectF(const GPointF &topleft, const GSizeF &size);
    GRectF(const GPointF &topleft, const GPointF &bottomRight);
    GRectF(real_t left, real_t top, real_t width, real_t height);
    GRectF(const GRect &rect);

    bool isNull() const;
    bool isEmpty() const;
    bool isValid() const;
    GRectF normalized() const;

    inline real_t left() const { return xp; }
    inline real_t top() const { return yp; }
    inline real_t right() const { return xp + w; }
    inline real_t bottom() const { return yp + h; }

    inline real_t x() const;
    inline real_t y() const;
    inline void setLeft(real_t pos);
    inline void setTop(real_t pos);
    inline void setRight(real_t pos);
    inline void setBottom(real_t pos);
    inline void setX(real_t pos) { setLeft(pos); }
    inline void setY(real_t pos) { setTop(pos); }

    inline GPointF topLeft() const { return GPointF(xp, yp); }
    inline GPointF bottomRight() const { return GPointF(xp+w, yp+h); }
    inline GPointF topRight() const { return GPointF(xp+w, yp); }
    inline GPointF bottomLeft() const { return GPointF(xp, yp+h); }
    inline GPointF center() const;

    void setTopLeft(const GPointF &p);
    void setBottomRight(const GPointF &p);
    void setTopRight(const GPointF &p);
    void setBottomLeft(const GPointF &p);

    void moveLeft(real_t pos);
    void moveTop(real_t pos);
    void moveRight(real_t pos);
    void moveBottom(real_t pos);
    void moveTopLeft(const GPointF &p);
    void moveBottomRight(const GPointF &p);
    void moveTopRight(const GPointF &p);
    void moveBottomLeft(const GPointF &p);
    void moveCenter(const GPointF &p);

    void translate(real_t dx, real_t dy);
    void translate(const GPointF &p);

    GRectF translated(real_t dx, real_t dy) const;
    GRectF translated(const GPointF &p) const;

    void moveTo(real_t x, real_t t);
    void moveTo(const GPointF &p);

    void setRect(real_t x, real_t y, real_t w, real_t h);
    void getRect(real_t *x, real_t *y, real_t *w, real_t *h) const;

    void setCoords(real_t x1, real_t y1, real_t x2, real_t y2);
    void getCoords(real_t *x1, real_t *y1, real_t *x2, real_t *y2) const;

    inline void adjust(real_t x1, real_t y1, real_t x2, real_t y2);
    inline GRectF adjusted(real_t x1, real_t y1, real_t x2, real_t y2) const;

    GSizeF size() const;
    real_t width() const;
    real_t height() const;
    void setWidth(real_t w);
    void setHeight(real_t h);
    void setSize(const GSizeF &s);

    GRectF operator|(const GRectF &r) const;
    GRectF operator&(const GRectF &r) const;
    GRectF& operator|=(const GRectF &r);
    GRectF& operator&=(const GRectF &r);

    bool contains(const GPointF &p) const;
    bool contains(real_t x, real_t y) const;
    bool contains(const GRectF &r) const;
    GRectF united(const GRectF &other) const;
    GRectF intersected(const GRectF &other) const;
    bool intersects(const GRectF &r) const;

    friend bool operator==(const GRectF &, const GRectF &);
    friend bool operator!=(const GRectF &, const GRectF &);

    GRect toRect() const;
    GRect toAlignedRect() const;

private:
    real_t xp;
    real_t yp;
    real_t w;
    real_t h;
};

inline GRectF::GRectF(real_t aleft, real_t atop, real_t awidth, real_t aheight)
    : xp(aleft), yp(atop), w(awidth), h(aheight)
{
}

inline GRectF::GRectF(const GPointF &atopLeft, const GSizeF &asize)
{
    xp = atopLeft.x();
    yp = atopLeft.y();
    w = asize.width();
    h = asize.height();
}

inline GRectF::GRectF(const GPointF &atopLeft, const GPointF &abottomRight)
{
    xp = atopLeft.x();
    yp = atopLeft.y();
    w = abottomRight.x() - xp;
    h = abottomRight.y() - yp;
}

inline GRectF::GRectF(const GRect &r)
    : xp((real_t)r.x()), yp((real_t)r.y()), w((real_t)r.width()), h((real_t)r.height())
{
}

inline bool GRectF::isNull() const
{ return w == 0. && h == 0.; }

inline bool GRectF::isEmpty() const
{ return w <= 0. || h <= 0.; }

inline bool GRectF::isValid() const
{ return w > 0. && h > 0.; }

inline real_t GRectF::x() const
{ return xp; }

inline real_t GRectF::y() const
{ return yp; }

inline void GRectF::setLeft(real_t pos) { real_t diff = pos - xp; xp += diff; w -= diff; }

inline void GRectF::setRight(real_t pos) { w = pos - xp; }

inline void GRectF::setTop(real_t pos) { real_t diff = pos - yp; yp += diff; h -= diff; }

inline void GRectF::setBottom(real_t pos) { h = pos - yp; }

inline void GRectF::setTopLeft(const GPointF &p) { setLeft(p.x()); setTop(p.y()); }

inline void GRectF::setTopRight(const GPointF &p) { setRight(p.x()); setTop(p.y()); }

inline void GRectF::setBottomLeft(const GPointF &p) { setLeft(p.x()); setBottom(p.y()); }

inline void GRectF::setBottomRight(const GPointF &p) { setRight(p.x()); setBottom(p.y()); }

inline GPointF GRectF::center() const
{ return GPointF(xp + w/2, yp + h/2); }

inline void GRectF::moveLeft(real_t pos) { xp = pos; }

inline void GRectF::moveTop(real_t pos) { yp = pos; }

inline void GRectF::moveRight(real_t pos) { xp = pos - w; }

inline void GRectF::moveBottom(real_t pos) { yp = pos - h; }

inline void GRectF::moveTopLeft(const GPointF &p) { moveLeft(p.x()); moveTop(p.y()); }

inline void GRectF::moveTopRight(const GPointF &p) { moveRight(p.x()); moveTop(p.y()); }

inline void GRectF::moveBottomLeft(const GPointF &p) { moveLeft(p.x()); moveBottom(p.y()); }

inline void GRectF::moveBottomRight(const GPointF &p) { moveRight(p.x()); moveBottom(p.y()); }

inline void GRectF::moveCenter(const GPointF &p) { xp = p.x() - w/2; yp = p.y() - h/2; }

inline real_t GRectF::width() const
{ return w; }

inline real_t GRectF::height() const
{ return h; }

inline GSizeF GRectF::size() const
{ return GSizeF(w, h); }

inline void GRectF::translate(real_t dx, real_t dy)
{
    xp += dx;
    yp += dy;
}

inline void GRectF::translate(const GPointF &p)
{
    xp += p.x();
    yp += p.y();
}

inline void GRectF::moveTo(real_t ax, real_t ay)
{
    xp = ax;
    yp = ay;
}

inline void GRectF::moveTo(const GPointF &p)
{
    xp = p.x();
    yp = p.y();
}

inline GRectF GRectF::translated(real_t dx, real_t dy) const
{ return GRectF(xp + dx, yp + dy, w, h); }

inline GRectF GRectF::translated(const GPointF &p) const
{ return GRectF(xp + p.x(), yp + p.y(), w, h); }

inline void GRectF::getRect(real_t *ax, real_t *ay, real_t *aaw, real_t *aah) const
{
    *ax = this->xp;
    *ay = this->yp;
    *aaw = this->w;
    *aah = this->h;
}

inline void GRectF::setRect(real_t ax, real_t ay, real_t aaw, real_t aah)
{
    this->xp = ax;
    this->yp = ay;
    this->w = aaw;
    this->h = aah;
}

inline void GRectF::getCoords(real_t *xp1, real_t *yp1, real_t *xp2, real_t *yp2) const
{
    *xp1 = xp;
    *yp1 = yp;
    *xp2 = xp + w;
    *yp2 = yp + h;
}

inline void GRectF::setCoords(real_t xp1, real_t yp1, real_t xp2, real_t yp2)
{
    xp = xp1;
    yp = yp1;
    w = xp2 - xp1;
    h = yp2 - yp1;
}

inline void GRectF::adjust(real_t xp1, real_t yp1, real_t xp2, real_t yp2)
{ xp += xp1; yp += yp1; w += xp2 - xp1; h += yp2 - yp1; }

inline GRectF GRectF::adjusted(real_t xp1, real_t yp1, real_t xp2, real_t yp2) const
{ return GRectF(xp + xp1, yp + yp1, w + xp2 - xp1, h + yp2 - yp1); }

inline void GRectF::setWidth(real_t aw)
{ this->w = aw; }

inline void GRectF::setHeight(real_t ah)
{ this->h = ah; }

inline void GRectF::setSize(const GSizeF &s)
{
    w = s.width();
    h = s.height();
}

inline bool GRectF::contains(real_t ax, real_t ay) const
{
    return contains(GPointF(ax, ay));
}

inline GRectF& GRectF::operator|=(const GRectF &r)
{
    *this = *this | r;
    return *this;
}

inline GRectF& GRectF::operator&=(const GRectF &r)
{
    *this = *this & r;
    return *this;
}


inline GRectF GRectF::intersected(const GRectF &r) const
{
	return *this & r;
}

inline GRectF GRectF::united(const GRectF &r) const
{
	return *this | r;
}

inline bool operator==(const GRectF &r1, const GRectF &r2)
{
    return gFuzzyCompare(r1.xp, r2.xp) && gFuzzyCompare(r1.yp, r2.yp)
           && gFuzzyCompare(r1.w, r2.w) && gFuzzyCompare(r1.h, r2.h);
}

inline bool operator!=(const GRectF &r1, const GRectF &r2)
{
    return !gFuzzyCompare(r1.xp, r2.xp) || !gFuzzyCompare(r1.yp, r2.yp)
           || !gFuzzyCompare(r1.w, r2.w) || !gFuzzyCompare(r1.h, r2.h);
}

inline GRect GRectF::toRect() const
{
    return GRect(gRound(xp), gRound(yp), gRound(w), gRound(h));
}

