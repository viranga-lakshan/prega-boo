import CoreData
import Foundation

final class CoreDataOfflineStore {
    static let shared = CoreDataOfflineStore()

    private enum Entity {
        static let track = "CachedTrackEntry"
        static let profile = "CachedMomProfile"
    }

    private let container: NSPersistentContainer

    private init() {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "PregaBooOffline", managedObjectModel: model)
        container.loadPersistentStores { _, error in
            if let error {
                #if DEBUG
                print("CoreData store load failed: \(error)")
                #endif
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func cacheTrackEntries(_ entries: [MomTrackEntry], momUserId: UUID, kind: MomTrackerKind) {
        let context = container.viewContext
        context.performAndWait {
            let request = NSFetchRequest<NSManagedObject>(entityName: Entity.track)
            request.predicate = NSPredicate(format: "momUserId == %@ AND trackerType == %@", momUserId.uuidString, kind.rawValue)

            do {
                let existing = try context.fetch(request)
                existing.forEach(context.delete)
                for entry in entries {
                    let row = NSEntityDescription.insertNewObject(forEntityName: Entity.track, into: context)
                    row.setValue(entry.id.uuidString, forKey: "id")
                    row.setValue(entry.momUserId.uuidString, forKey: "momUserId")
                    row.setValue(entry.trackerType, forKey: "trackerType")
                    row.setValue(entry.entryDate, forKey: "entryDate")
                    row.setValue(entry.valueNumeric, forKey: "valueNumeric")
                    row.setValue(entry.valueText, forKey: "valueText")
                    row.setValue(entry.note, forKey: "note")
                    row.setValue(entry.createdAt, forKey: "createdAt")
                }
                try context.save()
            } catch {
                context.rollback()
            }
        }
    }

    func loadTrackEntries(momUserId: UUID, kind: MomTrackerKind) -> [MomTrackEntry] {
        let context = container.viewContext
        var result: [MomTrackEntry] = []
        context.performAndWait {
            let request = NSFetchRequest<NSManagedObject>(entityName: Entity.track)
            request.predicate = NSPredicate(format: "momUserId == %@ AND trackerType == %@", momUserId.uuidString, kind.rawValue)
            request.sortDescriptors = [
                NSSortDescriptor(key: "entryDate", ascending: false),
                NSSortDescriptor(key: "createdAt", ascending: false)
            ]

            do {
                result = try context.fetch(request).compactMap { row in
                    guard let idString = row.value(forKey: "id") as? String,
                          let id = UUID(uuidString: idString),
                          let momIdString = row.value(forKey: "momUserId") as? String,
                          let momId = UUID(uuidString: momIdString),
                          let trackerType = row.value(forKey: "trackerType") as? String,
                          let entryDate = row.value(forKey: "entryDate") as? String
                    else { return nil }

                    return MomTrackEntry(
                        id: id,
                        momUserId: momId,
                        trackerType: trackerType,
                        entryDate: entryDate,
                        valueNumeric: row.value(forKey: "valueNumeric") as? Double,
                        valueText: row.value(forKey: "valueText") as? String,
                        note: row.value(forKey: "note") as? String,
                        createdAt: row.value(forKey: "createdAt") as? String
                    )
                }
            } catch {
                result = []
            }
        }
        return result
    }

    func cacheMomProfile(_ profile: MomProfile) {
        let context = container.viewContext
        context.performAndWait {
            let request = NSFetchRequest<NSManagedObject>(entityName: Entity.profile)
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "userId == %@", profile.userId.uuidString)

            do {
                let row = try context.fetch(request).first ?? NSEntityDescription.insertNewObject(forEntityName: Entity.profile, into: context)
                row.setValue(profile.userId.uuidString, forKey: "userId")
                row.setValue(profile.id?.uuidString, forKey: "id")
                row.setValue(profile.fullName, forKey: "fullName")
                row.setValue(profile.contactNumber, forKey: "contactNumber")
                row.setValue(profile.district, forKey: "district")
                row.setValue(profile.lmpDate, forKey: "lmpDate")
                row.setValue(profile.photoPath, forKey: "photoPath")
                try context.save()
            } catch {
                context.rollback()
            }
        }
    }

    func loadMomProfile(userId: UUID) -> MomProfile? {
        let context = container.viewContext
        var result: MomProfile?
        context.performAndWait {
            let request = NSFetchRequest<NSManagedObject>(entityName: Entity.profile)
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "userId == %@", userId.uuidString)

            do {
                guard let row = try context.fetch(request).first else {
                    result = nil
                    return
                }
                let id = (row.value(forKey: "id") as? String).flatMap(UUID.init(uuidString:))
                guard let fullName = row.value(forKey: "fullName") as? String,
                      let contactNumber = row.value(forKey: "contactNumber") as? String,
                      let district = row.value(forKey: "district") as? String else {
                    result = nil
                    return
                }
                result = MomProfile(
                    id: id,
                    userId: userId,
                    fullName: fullName,
                    contactNumber: contactNumber,
                    district: district,
                    lmpDate: row.value(forKey: "lmpDate") as? String,
                    photoPath: row.value(forKey: "photoPath") as? String
                )
            } catch {
                result = nil
            }
        }
        return result
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let track = NSEntityDescription()
        track.name = Entity.track
        track.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        track.properties = [
            attribute("id", .stringAttributeType),
            attribute("momUserId", .stringAttributeType),
            attribute("trackerType", .stringAttributeType),
            attribute("entryDate", .stringAttributeType),
            attribute("valueNumeric", .doubleAttributeType, isOptional: true),
            attribute("valueText", .stringAttributeType, isOptional: true),
            attribute("note", .stringAttributeType, isOptional: true),
            attribute("createdAt", .stringAttributeType, isOptional: true)
        ]

        let profile = NSEntityDescription()
        profile.name = Entity.profile
        profile.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        profile.properties = [
            attribute("id", .stringAttributeType, isOptional: true),
            attribute("userId", .stringAttributeType),
            attribute("fullName", .stringAttributeType),
            attribute("contactNumber", .stringAttributeType),
            attribute("district", .stringAttributeType),
            attribute("lmpDate", .stringAttributeType, isOptional: true),
            attribute("photoPath", .stringAttributeType, isOptional: true)
        ]

        model.entities = [track, profile]
        return model
    }

    private static func attribute(_ name: String, _ type: NSAttributeType, isOptional: Bool = false) -> NSAttributeDescription {
        let attr = NSAttributeDescription()
        attr.name = name
        attr.attributeType = type
        attr.isOptional = isOptional
        return attr
    }
}
