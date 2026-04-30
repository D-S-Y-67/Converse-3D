import SceneKit

struct F1CarBuilt {
    let node: SCNNode
    let rearWingFlap: SCNNode
    let smokeEmitters: [SCNNode]
}

enum F1CarBuilder {
    static func build(bodyColor: UIColor,
                      accentColor: UIColor,
                      cabinColor: UIColor,
                      treadRadius: CGFloat,
                      treadColor: UIColor,
                      treadStripeColor: UIColor) -> F1CarBuilt {
        let car = SCNNode()

        let bodyMat = makeMaterial(diffuse: bodyColor, metalness: 0.55, roughness: 0.25)
        let accentMat = makeMaterial(diffuse: accentColor, metalness: 0.4, roughness: 0.3)
        let darkMat = makeMaterial(diffuse: UIColor(white: 0.05, alpha: 1),
                                   metalness: 0.6, roughness: 0.35)
        let cockpitMat = makeMaterial(diffuse: cabinColor,
                                      metalness: 0.7, roughness: 0.18)

        let chassis = SCNBox(width: 1.4, height: 0.42, length: 4.4, chamferRadius: 0.12)
        chassis.firstMaterial = bodyMat
        let chassisN = SCNNode(geometry: chassis)
        chassisN.position = SCNVector3(0, 0.55, 0)
        car.addChildNode(chassisN)

        let nose = SCNBox(width: 0.85, height: 0.22, length: 1.6, chamferRadius: 0.08)
        nose.firstMaterial = bodyMat
        let noseN = SCNNode(geometry: nose)
        noseN.position = SCNVector3(0, 0.45, -2.85)
        car.addChildNode(noseN)

        let noseTip = SCNBox(width: 0.35, height: 0.16, length: 0.7, chamferRadius: 0.05)
        noseTip.firstMaterial = accentMat
        let noseTipN = SCNNode(geometry: noseTip)
        noseTipN.position = SCNVector3(0, 0.42, -3.85)
        car.addChildNode(noseTipN)

        let frontWing = SCNBox(width: 3.2, height: 0.06, length: 0.85,
                               chamferRadius: 0.02)
        frontWing.firstMaterial = darkMat
        let frontWingN = SCNNode(geometry: frontWing)
        frontWingN.position = SCNVector3(0, 0.20, -3.7)
        car.addChildNode(frontWingN)

        let frontWingAccent = SCNBox(width: 3.2, height: 0.04, length: 0.25,
                                     chamferRadius: 0.02)
        frontWingAccent.firstMaterial = accentMat
        let frontWingAccentN = SCNNode(geometry: frontWingAccent)
        frontWingAccentN.position = SCNVector3(0, 0.23, -3.4)
        car.addChildNode(frontWingAccentN)

        for x in [Float(-1.55), Float(1.55)] {
            let endplate = SCNBox(width: 0.08, height: 0.32, length: 0.85,
                                  chamferRadius: 0.02)
            endplate.firstMaterial = bodyMat
            let n = SCNNode(geometry: endplate)
            n.position = SCNVector3(x, 0.34, -3.7)
            car.addChildNode(n)
        }

        for x in [Float(-1.0), Float(1.0)] {
            let pod = SCNBox(width: 0.7, height: 0.45, length: 1.9,
                             chamferRadius: 0.18)
            pod.firstMaterial = bodyMat
            let n = SCNNode(geometry: pod)
            n.position = SCNVector3(x, 0.55, 0.4)
            car.addChildNode(n)

            let podAccent = SCNBox(width: 0.72, height: 0.10, length: 1.6,
                                   chamferRadius: 0.05)
            podAccent.firstMaterial = accentMat
            let an = SCNNode(geometry: podAccent)
            an.position = SCNVector3(x, 0.78, 0.4)
            car.addChildNode(an)
        }

        for x in [Float(-0.5), Float(0.5)] {
            let wall = SCNBox(width: 0.10, height: 0.55, length: 1.4,
                              chamferRadius: 0.04)
            wall.firstMaterial = cockpitMat
            let n = SCNNode(geometry: wall)
            n.position = SCNVector3(x, 0.95, -0.55)
            car.addChildNode(n)
        }

        let seat = SCNBox(width: 0.85, height: 0.20, length: 0.95,
                          chamferRadius: 0.08)
        seat.firstMaterial = cockpitMat
        let seatN = SCNNode(geometry: seat)
        seatN.position = SCNVector3(0, 0.86, -0.4)
        car.addChildNode(seatN)

        for x in [Float(-0.55), Float(0.55)] {
            let pillar = SCNBox(width: 0.10, height: 0.45, length: 0.10,
                                chamferRadius: 0.03)
            pillar.firstMaterial = darkMat
            let p = SCNNode(geometry: pillar)
            p.position = SCNVector3(x, 1.18, -0.95)
            p.eulerAngles.x = -0.18
            car.addChildNode(p)
        }
        let haloBar = SCNBox(width: 1.2, height: 0.10, length: 0.10,
                             chamferRadius: 0.03)
        haloBar.firstMaterial = darkMat
        let haloBarN = SCNNode(geometry: haloBar)
        haloBarN.position = SCNVector3(0, 1.40, -1.05)
        car.addChildNode(haloBarN)

        let airbox = SCNBox(width: 0.45, height: 0.7, length: 0.85,
                            chamferRadius: 0.10)
        airbox.firstMaterial = bodyMat
        let airboxN = SCNNode(geometry: airbox)
        airboxN.position = SCNVector3(0, 1.05, 0.5)
        car.addChildNode(airboxN)

        let airIntake = SCNBox(width: 0.35, height: 0.32, length: 0.18,
                               chamferRadius: 0.06)
        airIntake.firstMaterial = darkMat
        let airIntakeN = SCNNode(geometry: airIntake)
        airIntakeN.position = SCNVector3(0, 1.18, 0.10)
        car.addChildNode(airIntakeN)

        let engineBlock = SCNBox(width: 0.85, height: 0.45, length: 1.2,
                                 chamferRadius: 0.12)
        engineBlock.firstMaterial = darkMat
        let engineN = SCNNode(geometry: engineBlock)
        engineN.position = SCNVector3(0, 0.65, 1.4)
        car.addChildNode(engineN)

        let wingPillarL = SCNBox(width: 0.12, height: 1.4, length: 0.18,
                                 chamferRadius: 0.04)
        wingPillarL.firstMaterial = darkMat
        let wingPillarLN = SCNNode(geometry: wingPillarL)
        wingPillarLN.position = SCNVector3(-0.35, 1.45, 2.1)
        car.addChildNode(wingPillarLN)
        let wingPillarRN = wingPillarLN.flattenedClone()
        wingPillarRN.position = SCNVector3(0.35, 1.45, 2.1)
        car.addChildNode(wingPillarRN)

        let rearWing = SCNBox(width: 2.6, height: 0.10, length: 0.7,
                              chamferRadius: 0.03)
        rearWing.firstMaterial = darkMat
        let rearWingN = SCNNode(geometry: rearWing)
        rearWingN.position = SCNVector3(0, 2.05, 2.15)
        car.addChildNode(rearWingN)

        let rearFlap = SCNBox(width: 2.5, height: 0.07, length: 0.55,
                              chamferRadius: 0.03)
        rearFlap.firstMaterial = accentMat
        let rearFlapPivot = SCNNode()
        rearFlapPivot.position = SCNVector3(0, 2.25, 2.0)
        let rearFlapN = SCNNode(geometry: rearFlap)
        rearFlapN.position = SCNVector3(0, 0, 0.18)
        rearFlapPivot.addChildNode(rearFlapN)
        car.addChildNode(rearFlapPivot)

        for x in [Float(-1.30), Float(1.30)] {
            let endplate = SCNBox(width: 0.10, height: 0.55, length: 0.7,
                                  chamferRadius: 0.02)
            endplate.firstMaterial = bodyMat
            let n = SCNNode(geometry: endplate)
            n.position = SCNVector3(x, 2.18, 2.15)
            car.addChildNode(n)
        }

        let diffuser = SCNBox(width: 1.8, height: 0.18, length: 0.6,
                              chamferRadius: 0.05)
        diffuser.firstMaterial = darkMat
        let diffN = SCNNode(geometry: diffuser)
        diffN.position = SCNVector3(0, 0.18, 2.30)
        car.addChildNode(diffN)

        let frontWheelRadius = treadRadius * 0.95
        let rearWheelRadius = treadRadius * 1.05
        let frontWidth: CGFloat = 0.55
        let rearWidth: CGFloat = 0.62

        let wheels: [(x: Float, z: Float, r: CGFloat, w: CGFloat)] = [
            (-1.20, -2.05, frontWheelRadius, frontWidth),
            ( 1.20, -2.05, frontWheelRadius, frontWidth),
            (-1.25,  1.85, rearWheelRadius,  rearWidth),
            ( 1.25,  1.85, rearWheelRadius,  rearWidth)
        ]
        for w in wheels {
            let tire = SCNCylinder(radius: w.r, height: w.w)
            tire.firstMaterial = makeMaterial(diffuse: treadColor,
                                              metalness: 0.1, roughness: 0.85)
            let tireN = SCNNode(geometry: tire)
            tireN.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            tireN.position = SCNVector3(w.x, Float(w.r), w.z)
            car.addChildNode(tireN)

            let stripe = SCNTorus(ringRadius: w.r * 0.92, pipeRadius: 0.04)
            stripe.ringSegmentCount = 32
            stripe.pipeSegmentCount = 12
            stripe.firstMaterial = makeMaterial(diffuse: treadStripeColor,
                                                metalness: 0.1, roughness: 0.5,
                                                emission: treadStripeColor.withAlphaComponent(0.55))
            let stripeN = SCNNode(geometry: stripe)
            stripeN.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            stripeN.position = SCNVector3(w.x, Float(w.r), w.z)
            car.addChildNode(stripeN)
        }

        for x in [Float(-0.55), Float(0.55)] {
            let led = SCNBox(width: 0.28, height: 0.06, length: 0.05,
                             chamferRadius: 0.01)
            led.firstMaterial = makeMaterial(
                diffuse: UIColor.white,
                metalness: 0.0, roughness: 0.2,
                emission: UIColor(red: 1, green: 0.95, blue: 0.85, alpha: 1))
            let n = SCNNode(geometry: led)
            n.position = SCNVector3(x, 0.42, -3.78)
            car.addChildNode(n)
        }

        let tailLight = SCNBox(width: 0.35, height: 0.10, length: 0.05,
                               chamferRadius: 0.02)
        tailLight.firstMaterial = makeMaterial(
            diffuse: UIColor(red: 0.6, green: 0.05, blue: 0.05, alpha: 1),
            metalness: 0.0, roughness: 0.4,
            emission: UIColor(red: 1, green: 0.15, blue: 0.10, alpha: 1))
        let tailN = SCNNode(geometry: tailLight)
        tailN.position = SCNVector3(0, 1.95, 2.55)
        car.addChildNode(tailN)

        var emitters: [SCNNode] = []
        for x in [Float(-1.25), Float(1.25)] {
            let e = SCNNode()
            e.position = SCNVector3(x, 0.4, 2.3)
            car.addChildNode(e)
            emitters.append(e)
        }

        car.castsShadow = true

        return F1CarBuilt(node: car, rearWingFlap: rearFlapPivot,
                          smokeEmitters: emitters)
    }

    static func makeMaterial(diffuse: UIColor, metalness: CGFloat,
                             roughness: CGFloat,
                             emission: UIColor? = nil) -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = diffuse
        m.metalness.contents = metalness
        m.roughness.contents = roughness
        if let e = emission { m.emission.contents = e }
        return m
    }
}
