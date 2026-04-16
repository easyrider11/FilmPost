import Foundation

public struct AnalysisResponse: Codable, Equatable, Sendable {
    public let contextSummary: String
    public let recommendations: [Recommendation]

    public init(contextSummary: String, recommendations: [Recommendation]) {
        self.contextSummary = contextSummary
        self.recommendations = recommendations
    }

    enum CodingKeys: String, CodingKey {
        case contextSummary = "context_summary"
        case recommendations
    }
}

public struct Recommendation: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let style: String
    public let whyThisMatches: String
    public let directorNote: String
    public let emotionalGoal: String
    public let pose: String
    public let composition: String
    public let colorDirection: String
    public let cameraDistance: String
    public let lightingTip: String
    public let referenceFilmMood: String
    public let cinemaReference: CinemaReference

    public init(
        id: UUID = UUID(),
        style: String,
        whyThisMatches: String,
        directorNote: String,
        emotionalGoal: String,
        pose: String,
        composition: String,
        colorDirection: String,
        cameraDistance: String,
        lightingTip: String,
        referenceFilmMood: String,
        cinemaReference: CinemaReference
    ) {
        self.id = id
        self.style = style
        self.whyThisMatches = whyThisMatches
        self.directorNote = directorNote
        self.emotionalGoal = emotionalGoal
        self.pose = pose
        self.composition = composition
        self.colorDirection = colorDirection
        self.cameraDistance = cameraDistance
        self.lightingTip = lightingTip
        self.referenceFilmMood = referenceFilmMood
        self.cinemaReference = cinemaReference
    }

    enum CodingKeys: String, CodingKey {
        case style
        case whyThisMatches = "why_this_matches"
        case directorNote = "director_note"
        case emotionalGoal = "emotional_goal"
        case pose
        case composition
        case colorDirection = "color_direction"
        case cameraDistance = "camera_distance"
        case lightingTip = "lighting_tip"
        case referenceFilmMood = "reference_film_mood"
        case cinemaReference = "cinema_reference"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.style = try container.decode(String.self, forKey: .style)
        self.whyThisMatches = try container.decode(String.self, forKey: .whyThisMatches)
        self.directorNote = try container.decode(String.self, forKey: .directorNote)
        self.emotionalGoal = try container.decode(String.self, forKey: .emotionalGoal)
        self.pose = try container.decode(String.self, forKey: .pose)
        self.composition = try container.decode(String.self, forKey: .composition)
        self.colorDirection = try container.decode(String.self, forKey: .colorDirection)
        self.cameraDistance = try container.decode(String.self, forKey: .cameraDistance)
        self.lightingTip = try container.decode(String.self, forKey: .lightingTip)
        self.referenceFilmMood = try container.decode(String.self, forKey: .referenceFilmMood)
        self.cinemaReference = try container.decode(CinemaReference.self, forKey: .cinemaReference)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(style, forKey: .style)
        try container.encode(whyThisMatches, forKey: .whyThisMatches)
        try container.encode(directorNote, forKey: .directorNote)
        try container.encode(emotionalGoal, forKey: .emotionalGoal)
        try container.encode(pose, forKey: .pose)
        try container.encode(composition, forKey: .composition)
        try container.encode(colorDirection, forKey: .colorDirection)
        try container.encode(cameraDistance, forKey: .cameraDistance)
        try container.encode(lightingTip, forKey: .lightingTip)
        try container.encode(referenceFilmMood, forKey: .referenceFilmMood)
        try container.encode(cinemaReference, forKey: .cinemaReference)
    }
}

public struct CinemaReference: Codable, Equatable, Sendable {
    public let filmTitle: String
    public let director: String
    public let sceneAnchor: String
    public let whyItConnects: String
    public let borrowedTechnique: String

    public init(
        filmTitle: String,
        director: String,
        sceneAnchor: String,
        whyItConnects: String,
        borrowedTechnique: String
    ) {
        self.filmTitle = filmTitle
        self.director = director
        self.sceneAnchor = sceneAnchor
        self.whyItConnects = whyItConnects
        self.borrowedTechnique = borrowedTechnique
    }

    enum CodingKeys: String, CodingKey {
        case filmTitle = "film_title"
        case director
        case sceneAnchor = "scene_anchor"
        case whyItConnects = "why_it_connects"
        case borrowedTechnique = "borrowed_technique"
    }
}
