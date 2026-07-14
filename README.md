# Voxcordis

Application mobile IA de dépistage cardiovasculaire par analyse vocale.

L'application utilise un modèle **YAMNet** (transféré depuis TensorFlow Hub) pour extraire des embeddings vocaux, puis un classifieur entraîné pour détecter des signes vocaux associés à des risques cardiovasculaires ou laryngés. L'inférence s'exécute **directement sur le téléphone** via TensorFlow Lite, avec un basculement automatique vers l'API distante quand Internet est disponible.

---

## Architecture

```
voxcordis/
├── voxcordis_app/        # Application mobile Flutter (Android)
│   ├── lib/
│   │   ├── main.dart                   # Point d'entrée
│   │   ├── models/                     # Modèles de données
│   │   ├── providers/                  # State management (Provider)
│   │   ├── services/                   # Services (audio, TFLite, API, PDF)
│   │   ├── screens/                    # Écrans
│   │   ├── widgets/                    # Widgets réutilisables
│   │   └── database/                   # SQLite local
│   ├── android/app/src/main/kotlin/    # Plugin TFLite natif (Kotlin)
│   └── assets/models/                  # Modèles TFLite + scaler
│
├── voxcordis-api/        # Backend FastAPI (Python)
│   ├── main.py                        # FastAPI app
│   ├── core/
│   │   ├── model.py                   # Chargement & inférence Keras
│   │   ├── preprocessing.py           # YAMNet + extraction embedding
│   │   ├── risk.py                    # Logique de risque
│   │   └── auth.py                    # JWT auth
│   ├── routers/                       # Endpoints (/predict, /auth, /history)
│   └── models/                        # Modèles Keras entraînés
│
└── scripts/             # Scripts utilitaires
    └── export_yamnet_tflite.py        # Export YAMNet hub → TFLite
```

---

## Pipeline d'inférence

```
Microphone (16 kHz)
    ↓ Enregistrement 3s WAV
RMS Normalization
    ↓
YAMNet (TFLite) → Embedding [6, 1024]
    ↓ Moyenne temporelle
Embedding [1, 1024]
    ↓ StandardScaler (mean/std)
Scaled Embedding
    ↓
Classifier (TFLite) → Probabilités [Healthy, Laryngeal, Cardiac]
    ↓
Résultat + Risque + Recommandation
```

**Deux modes de fonctionnement :**

| Mode | Condition | Chemin |
|------|-----------|--------|
| **Online** | Internet + Token JWT | WAV → Backend FastAPI → YAMNet (TF Hub) → Keras → BDD |
| **Offline** | Pas Internet / pas de token | WAV → TFLite natif (YAMNet + Classifier) → SQLite local |

Le basculement est automatique : si l'API répond et que l'utilisateur est authentifié, l'analyse passe par le backend. Sinon, elle s'exécute localement sur le téléphone. Si l'appel API échoue, un fallback offline est déclenché.

---

## Fonctionnalités

- **Inscription / Connexion** — avec ou sans Internet (SQLite local en fallback)
- **Guide vocal** — 3 étapes illustrées pour bien enregistrer
- **Enregistrement 3 secondes** — WAV 16 kHz, mono
- **Analyse en temps réel** — écran de loading avec animation
- **Résultat** — badge de risque, message personnalisé, recommandation médicale
- **Export PDF** — rapport d'analyse partageable
- **Historique** — filtres par risque, suppression, export PDF
- **Auto-switch online/offline** — transparent pour l'utilisateur
- **Backend REST** — FastAPI avec authentification JWT et base PostgreSQL/SQLite

---

## Stack technique

### Mobile (Flutter — Dart)

| Technologie | Rôle |
|-------------|------|
| `provider` | State management |
| `record` | Enregistrement audio WAV |
| `sqflite` | Base SQLite locale |
| `permission_handler` | Permissions microphone |
| `http` | Communication avec l'API |
| `pdf` / `printing` | Génération et partage PDF |
| `intl` | Dates en français |
| `tensorflow-lite:2.17.0` | Inférence TFLite native Android (Java/Kotlin) |
| `tflite_native_service` | Plugin Dart ↔ Kotlin bridge |

### Backend (Python — FastAPI)

| Technologie | Rôle |
|-------------|------|
| `FastAPI` | Framework REST |
| `TensorFlow 2.20.0` | YAMNet + classifieur Keras |
| `TensorFlow Hub` | Modèle YAMNet pré-entraîné |
| `librosa` | Chargement audio |
| `joblib` | Scaler standardisation |
| `SQLAlchemy` | ORM base de données |
| `python-jose` | JWT authentication |
| `bcrypt` | Hash des mots de passe |

### Modèle

- **YAMNet** : modèle Google pré-entraîné sur AudioSet, utilisé comme extracteur d'embeddings (1024 dimensions)
- **Classifieur** : réseau de neurones entraîné par transfer learning sur bases de données médicales vocales
- **TFLite** : modèles quantifiés (float16) pour l'inférence mobile
- **3 classes** : Healthy (bas risque), Laryngeal (risque modéré), Cardiac (risque élevé)

---

## Installation & développement

### Prérequis

- Flutter SDK ≥ 3.9
- Android SDK (API 34+)
- JDK 11+
- Python ≥ 3.10
- Appareil Android physique (pour les tests)

### Backend (API)

```bash
cd voxcordis-api
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Variables d'environnement (optionnel)
export SECRET_KEY="votre-clé-secrète"
export DATABASE_URL="sqlite:///voxcordis.db"

# Lancer
uvicorn main:app --host 0.0.0.0 --port 7860 --reload
```

Documentation automatique : http://localhost:7860/docs

### Application mobile

```bash
cd voxcordis_app
flutter pub get

# Mode debug (backend local)
flutter run

# Mode release (backend distant)
flutter build apk --release
```

Le fichier `main.dart` bascule automatiquement :
- **`flutter run`** (debug) → backend local `http://192.168.100.139:7860`
- **`flutter build apk --release`** → backend distant `https://voxcordis-api.onrender.com`

Pour connecter le téléphone au backend local :
```bash
adb reverse tcp:7860 tcp:7860
```

---

## Déploiement

### Backend (Render)

Le backend est déployé sur Render. La branche `backend` est celle déployée.

```bash
git checkout backend
git merge develop
git push origin backend
```

Variables d'environnement requises :

| Variable | Description |
|----------|-------------|
| `SECRET_KEY` | Clé secrète JWT (obligatoire en prod) |
| `DATABASE_URL` | URL PostgreSQL ou SQLite |
| `ALLOWED_ORIGINS` | Origines CORS autorisées |
| `MODEL_PATH` | Chemin du modèle Keras |
| `SCALER_PATH` | Chemin du scaler joblib |

### Application mobile (Play Store)

1. Générer une keystore : `keytool -genkey -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`
2. Configurer les clés dans `android/key.properties`
3. Builder : `flutter build appbundle --release`
4. L'`app-release.aab` est dans `build/app/outputs/bundle/release/`

---

## Scripts utiles

```bash
# Exporter YAMNet depuis TF Hub vers TFLite
python scripts/export_yamnet_tflite.py

# Lancer le backend
./start_backend.sh
```

---

## Avertissement

**Voxcordis est un outil de dépistage uniquement.** Il ne constitue pas un diagnostic médical. Les résultats doivent être interprétés par un professionnel de santé qualifié. En cas de doute, consultez un médecin.

---

## Auteur

**VEBAMBA A Carine** — carinecontact.dev@gmail.com

Licence MIT.
