function toRad(a) {
    return a / 180.0 * Math.PI;
}

/*
 * Calculate geodesic distance (in m) between two points specified by latitude/longitude (in numeric degrees)
 * using Vincenty inverse formula for ellipsoids
 */
function distVincenty(lat1, lon1, lat2, lon2) {
  var a = 6378137, b = 6356752.3142,  f = 1/298.257223563;  // WGS-84 ellipsiod
  var L = toRad((lon2-lon1));
  var U1 = Math.atan((1-f) * Math.tan(toRad(lat1)));
  var U2 = Math.atan((1-f) * Math.tan(toRad(lat2)));
  var sinU1 = Math.sin(U1), cosU1 = Math.cos(U1);
  var sinU2 = Math.sin(U2), cosU2 = Math.cos(U2);

  var lambda = L, lambdaP = 2*Math.PI;
  var iterLimit = 20;
  while (Math.abs(lambda-lambdaP) > 1e-12 && --iterLimit>0) {
    var sinLambda = Math.sin(lambda), cosLambda = Math.cos(lambda);
    var sinSigma = Math.sqrt((cosU2*sinLambda) * (cosU2*sinLambda) + 
      (cosU1*sinU2-sinU1*cosU2*cosLambda) * (cosU1*sinU2-sinU1*cosU2*cosLambda));
    if (sinSigma==0) return 0;  // co-incident points
    var cosSigma = sinU1*sinU2 + cosU1*cosU2*cosLambda;
    var sigma = Math.atan2(sinSigma, cosSigma);
    var sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
    var cosSqAlpha = 1 - sinAlpha*sinAlpha;
    var cos2SigmaM = cosSigma - 2*sinU1*sinU2/cosSqAlpha;
    if (isNaN(cos2SigmaM)) cos2SigmaM = 0;  // equatorial line: cosSqAlpha=0 (§6)
    var C = f/16*cosSqAlpha*(4+f*(4-3*cosSqAlpha));
    lambdaP = lambda;
    lambda = L + (1-C) * f * sinAlpha *
      (sigma + C*sinSigma*(cos2SigmaM+C*cosSigma*(-1+2*cos2SigmaM*cos2SigmaM)));
  }
  if (iterLimit==0) return NaN  // formula failed to converge

  var uSq = cosSqAlpha * (a*a - b*b) / (b*b);
  var A = 1 + uSq/16384*(4096+uSq*(-768+uSq*(320-175*uSq)));
  var B = uSq/1024 * (256+uSq*(-128+uSq*(74-47*uSq)));
  var deltaSigma = B*sinSigma*(cos2SigmaM+B/4*(cosSigma*(-1+2*cos2SigmaM*cos2SigmaM)-
    B/6*cos2SigmaM*(-3+4*sinSigma*sinSigma)*(-3+4*cos2SigmaM*cos2SigmaM)));
  var s = b*A*(sigma-deltaSigma);

  s = s.toFixed(3); // round to 1mm precision
  return s;
}

console.log(distVincenty( 35.65500, 139.74472, 36.10056, 140.09111));

