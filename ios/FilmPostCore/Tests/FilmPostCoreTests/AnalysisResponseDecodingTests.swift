import Foundation
import Testing
@testable import FilmPostCore


@Test("AnalysisResponse decodes exactly three recommendation cards")
func analysisResponseDecodesThreeRecommendations() throws {
    let payload = """
    {
      "context_summary": "Soft metro light, clean lines, and enough negative space for restrained portrait direction.",
      "recommendations": [
        {
          "style": "Quiet Platform",
          "why_this_matches": "The background geometry supports a calm, architectural portrait.",
          "director_note": "Play the stillness like a withheld thought and let the gaze arrive after the body settles.",
          "emotional_goal": "Urban solitude with a polished inner calm.",
          "pose": "Keep one shoulder turned toward the tracks and let the gaze drift just beyond camera.",
          "composition": "Place the subject on the left third and leave open space in the direction of the rails.",
          "color_direction": "Favor cool silver blues with a gentle amber note in skin.",
          "camera_distance": "Use a medium close frame so the station texture still reads.",
          "lighting_tip": "Turn the face slightly up to catch the soft overhead spill.",
          "reference_film_mood": "Measured city melancholy with a polished analog restraint.",
          "cinema_reference": {
            "film_title": "Lost in Translation",
            "director": "Sofia Coppola",
            "scene_anchor": "Hotel-window pause before Tokyo fully arrives.",
            "why_it_connects": "The cool reflected light and spare geometry carry the same suspended urban loneliness.",
            "borrowed_technique": "Let negative space and a delayed gaze tell the emotional story."
          }
        },
        {
          "style": "Late Commute Stillness",
          "why_this_matches": "The spare background keeps attention on posture and expression without feeling empty.",
          "director_note": "Photograph the moment before someone decides whether to stay or leave.",
          "emotional_goal": "Tender hesitation held in public.",
          "pose": "Rest both hands lightly near the coat seams and keep the stance settled.",
          "composition": "Frame from mid torso and let the tiled wall build repeating rhythm behind the subject.",
          "color_direction": "Keep contrast low and work with slate, cream, and muted olive.",
          "camera_distance": "Use a medium shot that shares equal weight between subject and environment.",
          "lighting_tip": "Look for the brightest ceiling patch and step the subject under its edge instead of the center.",
          "reference_film_mood": "Tender urban restraint with a subdued night-train mood.",
          "cinema_reference": {
            "film_title": "Brief Encounter",
            "director": "David Lean",
            "scene_anchor": "Railway-platform pause charged by emotional restraint.",
            "why_it_connects": "The station setting makes distance and interruption feel emotionally legible.",
            "borrowed_technique": "Use shared space and sidelong posture instead of overt gesture."
          }
        },
        {
          "style": "Centered Noir Calm",
          "why_this_matches": "The symmetrical station perspective can make a still portrait feel deliberate and cinematic.",
          "director_note": "Let the space discipline the body until the stillness becomes tension.",
          "emotional_goal": "Formal control with underlying unease.",
          "pose": "Square the stance, lower the chin slightly, and keep the arms relaxed.",
          "composition": "Center the subject and let the tunnel lines pull inward behind them.",
          "color_direction": "Stay inside cool graphite tones with a small warm lift on skin.",
          "camera_distance": "Choose a wider medium distance to let the architecture carry tension.",
          "lighting_tip": "Expose for the face and allow the far practical lights to bloom softly.",
          "reference_film_mood": "Controlled metropolitan noir with understated tension.",
          "cinema_reference": {
            "film_title": "The Conformist",
            "director": "Bernardo Bertolucci",
            "scene_anchor": "Figure suspended inside severe architectural symmetry.",
            "why_it_connects": "The receding tunnel lines naturally create the same controlled visual pressure.",
            "borrowed_technique": "Use centered framing and measured distance to imply emotional entrapment."
          }
        }
      ]
    }
    """.data(using: .utf8)!

    let decoded = try JSONDecoder().decode(AnalysisResponse.self, from: payload)

    #expect(decoded.recommendations.count == 3)
    #expect(decoded.recommendations[0].style == "Quiet Platform")
    #expect(decoded.recommendations[0].cinemaReference.filmTitle == "Lost in Translation")
    #expect(decoded.recommendations[1].directorNote.contains("Photograph"))
}
