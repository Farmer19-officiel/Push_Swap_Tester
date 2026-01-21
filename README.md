# 📦 Push_Swap Stress Tester

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Python](https://img.shields.io/badge/Logic-Python-3776AB?style=for-the-badge&logo=python&logoColor=white)

Un outil de test intensif pour le projet **Push_swap** de l'école 42. Ce script automatise des centaines de tests pour vérifier la robustesse et la précision de votre algorithme de tri face à différents niveaux de désordre.

---

## 📸 Preview



---

## 🚀 Installation & Usage

### 1. Prérequis
Assurez-vous d'avoir les fichiers suivants dans le **même dossier** :
* `a.out` (votre exécutable Push_swap)
* `checker_linux` (le checker officiel)
* `benchmark.sh` (ce script)

### 2. Lancement
Donnez les droits d'exécution et lancez le benchmark :
```bash
chmod +x benchmark.sh
./benchmark.sh
```

---

## 🛠️ Détails des Tests

Le benchmark exécute **100 essais** pour chaque configuration suivante :

| Flag | Taille | Désordre | Description |
| :--- | :--- | :--- | :--- |
| `--simple` | 100 & 500 | 20% | Liste quasi-triée (test de stabilité). |
| `--medium` | 100 & 500 | 50% | Mélange intermédiaire. |
| `--complex` | 100 & 500 | 80% | Désordre massif (test de performance). |
| `--adaptive` | 100 & 500 | Random | Taux de désordre aléatoire entre 10% et 90%. |

### Fonctions Clés :
- **Anti-Doublons** : Utilise `random.sample` en Python pour garantir des nombres uniques.
- **Timeout Sécurisé** : Arrête les tests après 10s pour éviter les boucles infinies.
- **Score en %** : Affiche le taux de réussite exact par catégorie.

---

## ⚙️ Configuration personnalisée

Si vous utilisez un nom d'exécutable différent ou un autre tester (ex: `push_swap` au lieu de `a.out`), modifiez simplement la ligne d'exécution dans le script :

```bash
# Dans benchmark.sh, remplacez './a.out' par votre binaire
OUT=$(timeout "$TIMEOUT" ./push_swap $ARGS "$flag" 2>/dev/null)
