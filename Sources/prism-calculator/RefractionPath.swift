
import Foundation
import simd

struct Refraction {
    let origin: Point
    let incidencePoint: Point
    let incidenceVector: Vector
    let normal: Vector
    let refractionVector: Vector
}

struct RefractionPath {
    let first: Refraction?
    let second: Refraction?

    init(origin: Point,
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
            self.first = nil
            self.second = nil
            return
        }

        let firstRefractionVector = Self.refract(incidence: incomingRay, normal: firstFaceNormal, ior: outerRefractiveIndex / innerRefractiveIndex)

        self.first = Refraction(origin: origin,
                                incidencePoint: firstFaceHitPoint,
                                incidenceVector: incomingRay,
                                normal: firstFaceNormal,
                                refractionVector: firstRefractionVector)

        guard let secondFaceHitPoint = Self.intersectPlane(normal: -secondFaceNormal,
                                                           planeOrigin: secondFaceMid,
                                                           rayOrigin: firstFaceHitPoint,
                                                           rayDirection: firstRefractionVector) else {
            print("failed finding second hit point")
            self.second = nil
            return
        }

        let emergenceVector = Self.refract(incidence: firstRefractionVector, normal: -secondFaceNormal, ior: innerRefractiveIndex / outerRefractiveIndex)

        self.second = Refraction(origin: firstFaceHitPoint,
                                 incidencePoint: secondFaceHitPoint,
                                 incidenceVector: firstRefractionVector,
                                 normal: secondFaceNormal,
                                 refractionVector: emergenceVector)
    }

    init(origin: Point,
         incomingRay: Vector,
         outgoingRay: Vector,
         innerRefractiveIndex: Double,
         outerRefractiveIndex: Double,
         firstFaceMid: Point,
         secondFaceMid: Point) {
        // TODO: dont just align both to go horizontal through the glass

        let optimalFirstRayRefraction = (secondFaceMid - firstFaceMid).normalized
        let firstFaceNormal = Self.normalVectorFrom(incidence: incomingRay,
                                                    refraction: optimalFirstRayRefraction,
                                                    ior: outerRefractiveIndex / innerRefractiveIndex)

        let refractedRay = Self.refract(incidence: incomingRay, normal: firstFaceNormal, ior: outerRefractiveIndex / innerRefractiveIndex)

        // note that this hits the face from behind so the normal should be inverted
        let secondFaceNormal = -Self.normalVectorFrom(incidence: refractedRay,
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

    static func intersectPlane(normal: Vector, planeOrigin: Point, rayOrigin: Point, rayDirection: Vector) -> Vector? {
        // assuming vectors are all normalized
        let denom = simd_dot(-normal, rayDirection)

        guard denom > 1e-6 else {
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
        // Determination of unit normal vectors of aspherical surfaces given unit directional vectors of incoming and outgoing rays: comment
        // Antonín Mikš and Pavel Novák, 2012
        let dotProduct = abs(incidence.dot(refraction) - ior) / sqrt(1 + pow(ior, 2) - 2 * ior * incidence.dot(refraction))
        let normal = ((refraction - ior * incidence) / (sqrt(1 - pow(ior, 2) * (1 - pow(dotProduct, 2))) - ior * dotProduct))

        print("incidence: \(incidence.toFixed()) (\(incidence.length)), refraction: \(refraction.toFixed()) (\(refraction.length)), normal: \(normal.toFixed()) (\(normal.length))")
        return -normal
    }

    static func normalVectorFrom_old(incidence: Vector, refraction: Vector, ior: Double) -> Vector {
        // Determination of unit normal vectors of aspherical surfaces given unit directional vectors of incoming and outgoing rays
        // Psang Dain Lin and Chung-Yu Tsai, 2012

        guard (0.9999 ... 1.0001).contains(incidence.length), (0.9999 ... 1.0001).contains(refraction.length) else {
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
