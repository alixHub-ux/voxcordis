# ── Risk level logic ──────────────────────────────────────────────────
# This module determines the risk level and builds the full response
# based on the predicted class and confidence score.
#
# Risk mapping :
#   Class 2 (Cardiac)   + confidence >= 85% → HIGH
#   Class 2 (Cardiac)   + confidence <  85% → WATCH
#   Class 1 (Laryngeal) + confidence >= 85% → MEDIUM
#   Class 1 (Laryngeal) + confidence 65-84% → LOW_MEDIUM
#   Class 1 (Laryngeal) + confidence <  65% → UNCERTAIN
#   Class 0 (Healthy)   + confidence >= 85% → LOW
#   Class 0 (Healthy)   + confidence <  85% → UNCERTAIN
# ─────────────────────────────────────────────────────────────────────

DISCLAIMER = (
    "Voxcordis est un outil de dépistage. "
    "Ce résultat ne remplace pas un avis médical professionnel."
)


def get_risk_level(class_id: int, confidence: float) -> dict:
    """
    Determines risk level and builds the user-facing response
    based on predicted class and confidence score.

    Args:
        class_id   : int   — 0 (Healthy), 1 (Laryngeal), 2 (Cardiac)
        confidence : float — model confidence in % (0-100)

    Returns:
        dict with all fields needed for the mobile app display
    """

    # ── CARDIAC ───────────────────────────────────────────────────────
    if class_id == 2:

        if confidence >= 85:
            return {
                "risk_level"  : "HIGH",
                "risk_label"  : "ÉLEVÉ",
                "color_code"  : "#D32F2F",
                "title"       : "Risque cardiovasculaire potentiel détecté",
                "message"     : (
                    "Votre analyse vocale révèle des patterns associés "
                    "à un risque cardiovasculaire. "
                    "Ce n'est pas un diagnostic — c'est une alerte."
                ),
                "advice"      : (
                    "Consultez un cardiologue "
                    "dans les plus brefs délais."
                ),
                "reliability" : "Résultat fiable",
                "disclaimer"  : DISCLAIMER
            }

        else:
            return {
                "risk_level"  : "WATCH",
                "risk_label"  : "À SURVEILLER",
                "color_code"  : "#F57C00",
                "title"       : "Risque cardiovasculaire possible",
                "message"     : (
                    "Votre analyse vocale suggère un risque "
                    "cardiovasculaire possible. "
                    "La certitude du résultat est limitée."
                ),
                "advice"      : (
                    "Refaites l'analyse et consultez "
                    "un médecin par précaution."
                ),
                "reliability" : "Résultat à confirmer",
                "disclaimer"  : DISCLAIMER
            }

    # ── LARYNGEAL ─────────────────────────────────────────────────────
    elif class_id == 1:

        if confidence >= 85:
            return {
                "risk_level"  : "MEDIUM",
                "risk_label"  : "MODÉRÉ",
                "color_code"  : "#FFA000",
                "title"       : "Anomalie vocale détectée",
                "message"     : (
                    "Votre analyse vocale révèle des "
                    "caractéristiques inhabituelles dans votre voix."
                ),
                "advice"      : (
                    "Consultez un médecin généraliste "
                    "pour un bilan."
                ),
                "reliability" : "Résultat fiable",
                "disclaimer"  : DISCLAIMER
            }

        elif confidence >= 65:
            return {
                "risk_level"  : "LOW_MEDIUM",
                "risk_label"  : "FAIBLE-MODÉRÉ",
                "color_code"  : "#FFD600",
                "title"       : "Légère anomalie vocale",
                "message"     : (
                    "Votre analyse vocale révèle "
                    "une légère anomalie vocale."
                ),
                "advice"      : (
                    "Refaites l'analyse dans 24h. "
                    "Si le résultat persiste, "
                    "consultez un médecin généraliste."
                ),
                "reliability" : "Résultat à confirmer",
                "disclaimer"  : DISCLAIMER
            }

        else:
            return {
                "risk_level"  : "UNCERTAIN",
                "risk_label"  : "INCERTAIN",
                "color_code"  : "#9E9E9E",
                "title"       : "Résultat non concluant",
                "message"     : (
                    "Le résultat de l'analyse "
                    "n'est pas suffisamment concluant."
                ),
                "advice"      : (
                    "Refaites l'enregistrement dans "
                    "un endroit calme et silencieux."
                ),
                "reliability" : "Résultat insuffisant",
                "disclaimer"  : DISCLAIMER
            }

    # ── HEALTHY ───────────────────────────────────────────────────────
    else:

        if confidence >= 85:
            return {
                "risk_level"  : "LOW",
                "risk_label"  : "BAS",
                "color_code"  : "#388E3C",
                "title"       : "Aucun risque détecté",
                "message"     : (
                    "Votre analyse vocale ne révèle "
                    "aucune anomalie. "
                    "Continuez à surveiller votre santé régulièrement."
                ),
                "advice"      : (
                    "Aucune action immédiate requise."
                ),
                "reliability" : "Résultat fiable",
                "disclaimer"  : DISCLAIMER
            }

        else:
            return {
                "risk_level"  : "UNCERTAIN",
                "risk_label"  : "INCERTAIN",
                "color_code"  : "#9E9E9E",
                "title"       : "Résultat non concluant",
                "message"     : (
                    "Le résultat de l'analyse "
                    "n'est pas suffisamment concluant."
                ),
                "advice"      : (
                    "Refaites l'enregistrement dans "
                    "un endroit calme et silencieux."
                ),
                "reliability" : "Résultat insuffisant",
                "disclaimer"  : DISCLAIMER
            }


def build_response(prediction: dict) -> dict:
    """
    Takes the raw prediction from model.py and builds
    the complete response to send to the mobile app.

    Args:
        prediction : dict — output from core/model.py predict()
            {class_id, confidence, probabilities}

    Returns:
        dict — complete response ready to be serialized as JSON
    """
    risk = get_risk_level(
        class_id   = prediction["class_id"],
        confidence = prediction["confidence"]
    )

    return {
        "risk_level"  : risk["risk_level"],
        "risk_label"  : risk["risk_label"],
        "color_code"  : risk["color_code"],
        "title"       : risk["title"],
        "message"     : risk["message"],
        "advice"      : risk["advice"],
        "reliability" : risk["reliability"],
        "disclaimer"  : risk["disclaimer"]
    }