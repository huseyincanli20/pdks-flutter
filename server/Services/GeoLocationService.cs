using System;

namespace PdksApp.Services;

public static class GeoLocationService
{
    private const double EarthRadiusKm = 6371.0;

    /// <summary>
    /// Haversine formülü ile iki koordinat (enlem/boylam) arasındaki mesafeyi metre cinsinden hesaplar.
    /// </summary>
    public static double CalculateDistanceInMeters(double lat1, double lon1, double lat2, double lon2)
    {
        var dLat = DegreesToRadians(lat2 - lat1);
        var dLon = DegreesToRadians(lon2 - lon1);

        var rLat1 = DegreesToRadians(lat1);
        var rLat2 = DegreesToRadians(lat2);

        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2) * Math.Cos(rLat1) * Math.Cos(rLat2);

        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));

        return (EarthRadiusKm * c) * 1000; // Kilometreyi metreye çevir
    }

    private static double DegreesToRadians(double degrees)
    {
        return degrees * (Math.PI / 180.0);
    }
}
