#pragma once

#include "GGlobal.h"

class GSize
{
public:
    GSize();
    GSize(int32_t w, int32_t h);

    bool isNull() const;
    bool isEmpty() const;
    bool isValid() const;

    int32_t width() const;
    int32_t height() const;
    void setWidth(int32_t w);
    void setHeight(int32_t h);
    void transpose();

    void scale(int32_t w, int32_t h, AspectRatioMode mode);
    void scale(const GSize &s, AspectRatioMode mode);

    GSize expandedTo(const GSize &) const;
    GSize boundedTo(const GSize &) const;

    int32_t &rwidth();
    int32_t &rheight();

    GSize &operator+=(const GSize &);
    GSize &operator-=(const GSize &);
    GSize &operator*=(real_t c);
    GSize &operator/=(real_t c);

    friend inline bool operator==(const GSize &, const GSize &);
    friend inline bool operator!=(const GSize &, const GSize &);
    friend inline const GSize operator+(const GSize &, const GSize &);
    friend inline const GSize operator-(const GSize &, const GSize &);
    friend inline const GSize operator*(const GSize &, real_t);
    friend inline const GSize operator*(real_t, const GSize &);
    friend inline const GSize operator/(const GSize &, real_t);

private:
    int32_t wd;
    int32_t ht;
};
/*****************************************************************************
  GSize inline functions
 *****************************************************************************/

inline GSize::GSize()
{ wd = ht = -1; }

inline GSize::GSize(int32_t w, int32_t h)
{ wd = w; ht = h; }

inline bool GSize::isNull() const
{ return wd==0 && ht==0; }

inline bool GSize::isEmpty() const
{ return wd<1 || ht<1; }

inline bool GSize::isValid() const
{ return wd>=0 && ht>=0; }

inline int32_t GSize::width() const
{ return wd; }

inline int32_t GSize::height() const
{ return ht; }

inline void GSize::setWidth(int32_t w)
{ wd = w; }

inline void GSize::setHeight(int32_t h)
{ ht = h; }

inline void GSize::scale(int32_t w, int32_t h, AspectRatioMode mode)
{ scale(GSize(w, h), mode); }

inline int32_t &GSize::rwidth()
{ return wd; }

inline int32_t &GSize::rheight()
{ return ht; }

inline GSize &GSize::operator+=(const GSize &s)
{ wd+=s.wd; ht+=s.ht; return *this; }

inline GSize &GSize::operator-=(const GSize &s)
{ wd-=s.wd; ht-=s.ht; return *this; }

inline GSize &GSize::operator*=(real_t c)
{ wd = gRound(wd*c); ht = gRound(ht*c); return *this; }

inline bool operator==(const GSize &s1, const GSize &s2)
{ return s1.wd == s2.wd && s1.ht == s2.ht; }

inline bool operator!=(const GSize &s1, const GSize &s2)
{ return s1.wd != s2.wd || s1.ht != s2.ht; }

inline const GSize operator+(const GSize & s1, const GSize & s2)
{ return GSize(s1.wd+s2.wd, s1.ht+s2.ht); }

inline const GSize operator-(const GSize &s1, const GSize &s2)
{ return GSize(s1.wd-s2.wd, s1.ht-s2.ht); }

inline const GSize operator*(const GSize &s, real_t c)
{ return GSize(gRound(s.wd*c), gRound(s.ht*c)); }

inline const GSize operator*(real_t c, const GSize &s)
{ return GSize(gRound(s.wd*c), gRound(s.ht*c)); }

inline GSize &GSize::operator/=(real_t c)
{
    wd = gRound(wd/c); ht = gRound(ht/c);
    return *this;
}

inline const GSize operator/(const GSize &s, real_t c)
{
    return GSize(gRound(s.wd/c), gRound(s.ht/c));
}

inline GSize GSize::expandedTo(const GSize & otherSize) const
{
    return GSize(gMax(wd,otherSize.wd), gMax(ht,otherSize.ht));
}

inline GSize GSize::boundedTo(const GSize & otherSize) const
{
    return GSize(gMin(wd,otherSize.wd), gMin(ht,otherSize.ht));
}

class GSizeF
{
public:
    GSizeF();
    GSizeF(const GSize &sz);
    GSizeF(real_t w, real_t h);

    bool isNull() const;
    bool isEmpty() const;
    bool isValid() const;

    real_t width() const;
    real_t height() const;
    void setWidth(real_t w);
    void setHeight(real_t h);
    void transpose();

    void scale(real_t w, real_t h, AspectRatioMode mode);
    void scale(const GSizeF &s, AspectRatioMode mode);

    GSizeF expandedTo(const GSizeF &) const;
    GSizeF boundedTo(const GSizeF &) const;

    real_t &rwidth();
    real_t &rheight();

    GSizeF &operator+=(const GSizeF &);
    GSizeF &operator-=(const GSizeF &);
    GSizeF &operator*=(real_t c);
    GSizeF &operator/=(real_t c);

    friend inline bool operator==(const GSizeF &, const GSizeF &);
    friend inline bool operator!=(const GSizeF &, const GSizeF &);
    friend inline const GSizeF operator+(const GSizeF &, const GSizeF &);
    friend inline const GSizeF operator-(const GSizeF &, const GSizeF &);
    friend inline const GSizeF operator*(const GSizeF &, real_t);
    friend inline const GSizeF operator*(real_t, const GSizeF &);
    friend inline const GSizeF operator/(const GSizeF &, real_t);

    inline GSize toSize() const;

private:
    real_t wd;
    real_t ht;
};


/*****************************************************************************
  GSizeF inline functions
 *****************************************************************************/

inline GSizeF::GSizeF()
{ wd = ht = -1.; }

inline GSizeF::GSizeF(const GSize &sz)
    : wd((real_t)sz.width()), ht((real_t)sz.height())
{
}

inline GSizeF::GSizeF(real_t w, real_t h)
{ wd = w; ht = h; }

inline bool GSizeF::isNull() const
{ return gIsNull(wd) && gIsNull(ht); }

inline bool GSizeF::isEmpty() const
{ return wd <= 0. || ht <= 0.; }

inline bool GSizeF::isValid() const
{ return wd >= 0. && ht >= 0.; }

inline real_t GSizeF::width() const
{ return wd; }

inline real_t GSizeF::height() const
{ return ht; }

inline void GSizeF::setWidth(real_t w)
{ wd = w; }

inline void GSizeF::setHeight(real_t h)
{ ht = h; }

inline void GSizeF::scale(real_t w, real_t h, AspectRatioMode mode)
{ scale(GSizeF(w, h), mode); }

inline real_t &GSizeF::rwidth()
{ return wd; }

inline real_t &GSizeF::rheight()
{ return ht; }

inline GSizeF &GSizeF::operator+=(const GSizeF &s)
{ wd += s.wd; ht += s.ht; return *this; }

inline GSizeF &GSizeF::operator-=(const GSizeF &s)
{ wd -= s.wd; ht -= s.ht; return *this; }

inline GSizeF &GSizeF::operator*=(real_t c)
{ wd *= c; ht *= c; return *this; }

inline bool operator==(const GSizeF &s1, const GSizeF &s2)
{ return gFuzzyCompare(s1.wd, s2.wd) && gFuzzyCompare(s1.ht, s2.ht); }

inline bool operator!=(const GSizeF &s1, const GSizeF &s2)
{ return !gFuzzyCompare(s1.wd, s2.wd) || !gFuzzyCompare(s1.ht, s2.ht); }

inline const GSizeF operator+(const GSizeF & s1, const GSizeF & s2)
{ return GSizeF(s1.wd+s2.wd, s1.ht+s2.ht); }

inline const GSizeF operator-(const GSizeF &s1, const GSizeF &s2)
{ return GSizeF(s1.wd-s2.wd, s1.ht-s2.ht); }

inline const GSizeF operator*(const GSizeF &s, real_t c)
{ return GSizeF(s.wd*c, s.ht*c); }

inline const GSizeF operator*(real_t c, const GSizeF &s)
{ return GSizeF(s.wd*c, s.ht*c); }

inline GSizeF &GSizeF::operator/=(real_t c)
{
    wd = wd/c; ht = ht/c;
    return *this;
}

inline const GSizeF operator/(const GSizeF &s, real_t c)
{
    return GSizeF(s.wd/c, s.ht/c);
}

inline GSizeF GSizeF::expandedTo(const GSizeF & otherSize) const
{
    return GSizeF(gMax(wd,otherSize.wd), gMax(ht,otherSize.ht));
}

inline GSizeF GSizeF::boundedTo(const GSizeF & otherSize) const
{
    return GSizeF(gMin(wd,otherSize.wd), gMin(ht,otherSize.ht));
}

inline GSize GSizeF::toSize() const
{
    return GSize(gRound(wd), gRound(ht));
}
