#pragma once
#include "GGlobal.h"

class GPoint
{
public:
    GPoint();
    GPoint(int32_t xpos, int32_t ypos);

    bool isNull() const;

    int32_t x() const;
    int32_t y() const;
    void setX(int32_t x);
    void setY(int32_t y);
	void setPos( int32_t x, int32_t y );

    int32_t &rx();
    int32_t &ry();

    GPoint &operator+=(const GPoint &p);
    GPoint &operator-=(const GPoint &p);

    GPoint &operator*=(float c);
    GPoint &operator*=(double c);
    GPoint &operator*=(int32_t c);

    GPoint &operator/=(real_t c);

    friend inline bool operator==(const GPoint &, const GPoint &);
    friend inline bool operator!=(const GPoint &, const GPoint &);
    friend inline const GPoint operator+(const GPoint &, const GPoint &);
    friend inline const GPoint operator-(const GPoint &, const GPoint &);
    friend inline const GPoint operator*(const GPoint &, float);
    friend inline const GPoint operator*(float, const GPoint &);
    friend inline const GPoint operator*(const GPoint &, double);
    friend inline const GPoint operator*(double, const GPoint &);
    friend inline const GPoint operator*(const GPoint &, int32_t);
    friend inline const GPoint operator*(int32_t, const GPoint &);
    friend inline const GPoint operator-(const GPoint &);
    friend inline const GPoint operator/(const GPoint &, real_t);

private:
    int32_t xp;
    int32_t yp;
};

inline GPoint::GPoint()
{ xp=0; yp=0; }

inline GPoint::GPoint(int32_t xpos, int32_t ypos)
{ xp = xpos; yp = ypos; }

inline bool GPoint::isNull() const
{ return xp == 0 && yp == 0; }

inline int32_t GPoint::x() const
{ return xp; }

inline int32_t GPoint::y() const
{ return yp; }

inline void GPoint::setX(int32_t xpos)
{ xp = xpos; }

inline void GPoint::setY(int32_t ypos)
{ yp = ypos; }

inline void GPoint::setPos( int32_t xpos, int32_t ypos )
{ xp = xpos; yp = ypos; }

inline int32_t &GPoint::rx()
{ return xp; }

inline int32_t &GPoint::ry()
{ return yp; }

inline GPoint &GPoint::operator+=(const GPoint &p)
{ xp+=p.xp; yp+=p.yp; return *this; }

inline GPoint &GPoint::operator-=(const GPoint &p)
{ xp-=p.xp; yp-=p.yp; return *this; }

inline GPoint &GPoint::operator*=(float c)
{ xp = gRound(xp*c); yp = gRound(yp*c); return *this; }

inline GPoint &GPoint::operator*=(double c)
{ xp = gRound(xp*c); yp = gRound(yp*c); return *this; }

inline GPoint &GPoint::operator*=(int32_t c)
{ xp = xp*c; yp = yp*c; return *this; }

inline bool operator==(const GPoint &p1, const GPoint &p2)
{ return p1.xp == p2.xp && p1.yp == p2.yp; }

inline bool operator!=(const GPoint &p1, const GPoint &p2)
{ return p1.xp != p2.xp || p1.yp != p2.yp; }

inline const GPoint operator+(const GPoint &p1, const GPoint &p2)
{ return GPoint(p1.xp+p2.xp, p1.yp+p2.yp); }

inline const GPoint operator-(const GPoint &p1, const GPoint &p2)
{ return GPoint(p1.xp-p2.xp, p1.yp-p2.yp); }

inline const GPoint operator*(const GPoint &p, float c)
{ return GPoint(gRound(p.xp*c), gRound(p.yp*c)); }

inline const GPoint operator*(const GPoint &p, double c)
{ return GPoint(gRound(p.xp*c), gRound(p.yp*c)); }

inline const GPoint operator*(const GPoint &p, int32_t c)
{ return GPoint(p.xp*c, p.yp*c); }

inline const GPoint operator*(float c, const GPoint &p)
{ return GPoint(gRound(p.xp*c), gRound(p.yp*c)); }

inline const GPoint operator*(double c, const GPoint &p)
{ return GPoint(gRound(p.xp*c), gRound(p.yp*c)); }

inline const GPoint operator*(int32_t c, const GPoint &p)
{ return GPoint(p.xp*c, p.yp*c); }

inline const GPoint operator-(const GPoint &p)
{ return GPoint(-p.xp, -p.yp); }

inline GPoint &GPoint::operator/=(real_t c)
{
    xp = gRound(xp/c);
    yp = gRound(yp/c);
    return *this;
}

inline const GPoint operator/(const GPoint &p, real_t c)
{
    return GPoint(gRound(p.xp/c), gRound(p.yp/c));
}

class GPointF
{
public:
    GPointF();
    GPointF(const GPoint &p);
    GPointF(real_t xpos, real_t ypos);

    bool isNull() const;

    real_t x() const;
    real_t y() const;
    void setX(real_t x);
    void setY(real_t y);
	void setPos( real_t x, real_t y );

    real_t &rx();
    real_t &ry();

    GPointF &operator+=(const GPointF &p);
    GPointF &operator-=(const GPointF &p);
    GPointF &operator*=(real_t c);
    GPointF &operator/=(real_t c);

    friend inline bool operator==(const GPointF &, const GPointF &);
    friend inline bool operator!=(const GPointF &, const GPointF &);
    friend inline const GPointF operator+(const GPointF &, const GPointF &);
    friend inline const GPointF operator-(const GPointF &, const GPointF &);
    friend inline const GPointF operator*(real_t, const GPointF &);
    friend inline const GPointF operator*(const GPointF &, real_t);
    friend inline const GPointF operator-(const GPointF &);
    friend inline const GPointF operator/(const GPointF &, real_t);

    GPoint toPoint() const;

private:
    friend class QMatrix;
    friend class QTransform;

    real_t xp;
    real_t yp;
};

/*****************************************************************************
  GPointF inline functions
 *****************************************************************************/

inline GPointF::GPointF() : xp(0), yp(0) { }

inline GPointF::GPointF(real_t xpos, real_t ypos) : xp(xpos), yp(ypos) { }

inline GPointF::GPointF(const GPoint &p) : xp((real_t)p.x()), yp((real_t)p.y()) { }

inline bool GPointF::isNull() const
{
    return gIsNull(xp) && gIsNull(yp);
}

inline real_t GPointF::x() const
{
    return xp;
}

inline real_t GPointF::y() const
{
    return yp;
}

inline void GPointF::setX(real_t xpos)
{
    xp = xpos;
}

inline void GPointF::setY(real_t ypos)
{
    yp = ypos;
}

inline void GPointF::setPos( real_t xpos, real_t ypos )
{
	xp = xpos; yp = ypos;
}

inline real_t &GPointF::rx()
{
    return xp;
}

inline real_t &GPointF::ry()
{
    return yp;
}

inline GPointF &GPointF::operator+=(const GPointF &p)
{
    xp+=p.xp;
    yp+=p.yp;
    return *this;
}

inline GPointF &GPointF::operator-=(const GPointF &p)
{
    xp-=p.xp; yp-=p.yp; return *this;
}

inline GPointF &GPointF::operator*=(real_t c)
{
    xp*=c; yp*=c; return *this;
}

inline bool operator==(const GPointF &p1, const GPointF &p2)
{
    return gFuzzyIsNull(p1.xp - p2.xp) && gFuzzyIsNull(p1.yp - p2.yp);
}

inline bool operator!=(const GPointF &p1, const GPointF &p2)
{
    return !gFuzzyIsNull(p1.xp - p2.xp) || !gFuzzyIsNull(p1.yp - p2.yp);
}

inline const GPointF operator+(const GPointF &p1, const GPointF &p2)
{
    return GPointF(p1.xp+p2.xp, p1.yp+p2.yp);
}

inline const GPointF operator-(const GPointF &p1, const GPointF &p2)
{
    return GPointF(p1.xp-p2.xp, p1.yp-p2.yp);
}

inline const GPointF operator*(const GPointF &p, real_t c)
{
    return GPointF(p.xp*c, p.yp*c);
}

inline const GPointF operator*(real_t c, const GPointF &p)
{
    return GPointF(p.xp*c, p.yp*c);
}

inline const GPointF operator-(const GPointF &p)
{
    return GPointF(-p.xp, -p.yp);
}

inline GPointF &GPointF::operator/=(real_t c)
{
    xp/=c;
    yp/=c;
    return *this;
}

inline const GPointF operator/(const GPointF &p, real_t c)
{
    return GPointF(p.xp/c, p.yp/c);
}

inline GPoint GPointF::toPoint() const
{
    return GPoint(gRound(xp), gRound(yp));
}
