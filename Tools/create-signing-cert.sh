#!/bin/bash
#
# Erstellt ein eigenes Signierzertifikat für O.C. Flow.
#
# Warum: ohne Zertifikat signiert `make install` ad hoc, und diese Signatur ändert sich bei
# jedem Bauen. macOS hängt die Bedienungshilfen-Freigabe an die Signatur, also muss sie nach
# jedem Update neu erteilt werden. Ein eigenes Zertifikat bleibt gleich, damit auch die
# Signatur, damit auch die Freigabe.
#
# Das Zertifikat ist selbst ausgestellt und gratis. Es taugt nicht zur Weitergabe an Fremde,
# dafür bräuchte man ein Apple-Zertifikat. Für den eigenen Rechner reicht es.
#
# Einmal ausführen:
#
#     bash Tools/create-signing-cert.sh
#
# Danach einmal `make install`. Beim Signieren fragt der Schlüsselbund, ob codesign den
# Schlüssel verwenden darf: auf „Immer erlauben" klicken. Ab dann ist nie wieder etwas zu tun.

set -euo pipefail

NAME="OC Flow Dev"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-identity -v -p codesigning 2>/dev/null | grep -q "$NAME"; then
    echo "Zertifikat \"$NAME\" ist schon vorhanden. Nichts zu tun."
    security find-identity -v -p codesigning | grep "$NAME"
    exit 0
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "Erstelle Zertifikat \"$NAME\" …"

# extendedKeyUsage=codeSigning ist der Teil, der es überhaupt zum Signieren taugt; ohne den
# findet `security find-identity -p codesigning` es später nicht.
cat > "$WORK/cert.conf" <<EOF
[ req ]
distinguished_name = dn
prompt = no
x509_extensions = ext

[ dn ]
CN = $NAME

[ ext ]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
EOF

openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
    -keyout "$WORK/key.pem" -out "$WORK/cert.pem" -config "$WORK/cert.conf" 2>/dev/null

openssl pkcs12 -export -inkey "$WORK/key.pem" -in "$WORK/cert.pem" \
    -out "$WORK/cert.p12" -passout pass: 2>/dev/null

# -T /usr/bin/codesign: codesign darf den Schlüssel benutzen. Beim ersten Mal fragt der
# Schlüsselbund trotzdem einmal nach, das ist der Klick auf „Immer erlauben".
security import "$WORK/cert.p12" -k "$KEYCHAIN" -P "" -T /usr/bin/codesign -T /usr/bin/security

echo "Hinterlege Vertrauen zum Signieren …"

# Selbst ausgestellt heißt: niemand bürgt dafür, also muss der Rechner es selbst als
# vertrauenswürdig eintragen, sonst verweigert codesign die Kette. Erst im eigenen
# Benutzerkonto versuchen, das braucht kein Passwort.
if security add-trusted-cert -r trustRoot -p codeSign -k "$KEYCHAIN" "$WORK/cert.pem" 2>/dev/null; then
    echo "Vertrauen im Benutzer-Schlüsselbund eingetragen."
else
    echo "Dafür braucht macOS dein Passwort:"
    sudo security add-trusted-cert -d -r trustRoot -p codeSign \
        -k /Library/Keychains/System.keychain "$WORK/cert.pem"
fi

echo
if security find-identity -v -p codesigning | grep -q "$NAME"; then
    echo "Fertig. Das Makefile nimmt das Zertifikat ab jetzt von allein:"
    security find-identity -v -p codesigning | grep "$NAME"
    echo
    echo "Jetzt einmal:  make install"
    echo "Beim Signieren fragt der Schlüsselbund nach, dort auf „Immer erlauben\" klicken."
    echo "Danach hält die Bedienungshilfen-Freigabe über alle künftigen Updates."
else
    echo "Das Zertifikat wurde erstellt, taucht aber nicht als Signier-Identität auf."
    echo "Prüfen mit: security find-identity -v -p codesigning"
    exit 1
fi
