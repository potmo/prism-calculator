
import Foundation
import simd

struct RefractionPath {

    let origin: Point
    let firstHitPoint: Point
    let secondHitPoint: Point
    let emergenceVector: Vector
    let incomingVector: Vector
    let firstFaceNormal: Vector
    let secondFaceNormal: Vector
    let firstRefractionVector: Vector


    init?(origin: Point,
          incomingRay: Vector,
          innerRefractiveIndex: Double,
          outerRefractiveIndex: Double,
          firstFaceMid: Point,
          firstFaceNormal: Vector,
          secondFaceMid: Point,
          secondFaceNormal: Vector) {

        guard let firstFaceHitPoint = Self.intersectPlane(normal: firstFaceNormal,
                                                          planeOrigin: firstFaceMid,
                                                          rayOrigin: origin,
                                                          rayDirection: incomingRay) else {
            print("failed finding first hit point")
            return nil
        }

        let firstRefractionVector = Self.refract(incidence: incomingRay, normal: firstFaceNormal, ior: outerRefractiveIndex / innerRefractiveIndex)

        guard let secondFaceHitPoint = Self.intersectPlane(normal: -secondFaceNormal,
                                                           planeOrigin: secondFaceMid,
                                                           rayOrigin: firstFaceHitPoint,
                                                           rayDirection: firstRefractionVector) else {
            print("failed finding second hit point")
            return nil
        }

        let emergenceVector = Self.refract(incidence: firstRefractionVector, normal: -secondFaceNormal, ior: innerRefractiveIndex / outerRefractiveIndex)

        self.origin = origin
        self.firstHitPoint = firstFaceHitPoint
        self.secondHitPoint = secondFaceHitPoint
        self.emergenceVector = emergenceVector
        self.firstFaceNormal = firstFaceNormal
        self.secondFaceNormal = secondFaceNormal
        self.incomingVector = incomingRay
        self.firstRefractionVector = firstRefractionVector
        
    }

    init?(origin: Point,
          incomingRay: Vector,
          outgoingRay: Vector,
          innerRefractiveIndex: Double,
          outerRefractiveIndex: Double,
          firstFaceMid: Point,
          secondFaceMid: Point){

        // TODO: dont just align both to go horizontal through the glass

        //TODO: Does the vectors have to be in the same quadrant or something for this to work? The normal is not normalized when returned
        let firstFaceNormal = Self.normalVectorFrom(incidence: incomingRay,
                                                    refraction: [1,0,0],
                                                    ior: outerRefractiveIndex / innerRefractiveIndex)

        // note that this hits the face from behind so the normal should be inverted
        let secondFaceNormal = -Self.normalVectorFrom(incidence: [1,0,0],
                                                      refraction: outgoingRay,
                                                      ior: innerRefractiveIndex / outerRefractiveIndex)

        self.init(origin: origin,
                  incomingRay: incomingRay,
                  innerRefractiveIndex: innerRefractiveIndex,
                  outerRefractiveIndex: outerRefractiveIndex,
                  firstFaceMid: firstFaceMid,
                  firstFaceNormal: firstFaceNormal,
                  secondFaceMid: secondFaceMid,
                  secondFaceNormal: secondFaceNormal)

    }


    static func intersectPlane(normal: Vector, planeOrigin: Point, rayOrigin: Point, rayDirection: Vector) -> Vector?{
        // assuming vectors are all normalized
        let denom = simd_dot(-normal, rayDirection);

        guard (denom > 1e-6) else {
            // parallel to plane
            return nil
        }

        let p0l0 = planeOrigin - rayOrigin
        let t = simd_dot(p0l0, -normal) / denom
        return rayOrigin + rayDirection * t
    }


    static func refract(incidence: Vector, normal: Vector, ior: Double) -> Vector {
        let c = (-normal).dot(incidence)
        let r = ior
        let n = normal
        let l = incidence
        let refraction = r * l + (r * c - sqrt(1 - r * r * (1 - c * c))) * n
        return refraction
    }

    static func normalVectorFrom(incidence: Vector, refraction: Vector, ior: Double) -> Vector {

        // Determination of unit normal vectors of aspherical surfaces given unit directional vectors of incoming and outgoing rays
        // Psang Dain Lin and Chung-Yu Tsai, 2012

        guard (0.9999...1.0001).contains(incidence.length), (0.9999...1.0001).contains(refraction.length) else {
            fatalError("not normalized")
        }

        // if they are paralell then the normal is negative to the incidence
        if incidence.dot(refraction) == 1.0 {
            return incidence.normalized * -1
        }

        let idotr = incidence.dot(refraction)
        let sinIncidence: Double = sqrt(1 - idotr ^ 2) / sqrt(ior ^ 2 + 1 - 2 * ior * idotr)
        let cosIncidence: Double = abs(ior - idotr) / sqrt(ior ^ 2 + 1 - 2 * ior * idotr)
        let sinRefraction: Double = ior * sqrt(1 - idotr ^ 2) / sqrt(ior ^ 2 + 1 - 2 * ior * idotr)
        let cosRefraction: Double = abs(1 - ior * idotr) / sqrt(ior ^ 2 + 1 - 2 * ior * idotr)

        let firstPartNormal: Vector = ((((cosIncidence * cosRefraction + sinIncidence * sinRefraction) * sinIncidence) / (sinIncidence * cosRefraction - cosIncidence * sinRefraction)) - cosIncidence) * incidence
        let secondPartNormal: Vector = (sinIncidence / (sinIncidence * cosRefraction - cosIncidence * sinRefraction)) * refraction
        let normal: Vector = firstPartNormal - secondPartNormal

        return normal
    }
}

