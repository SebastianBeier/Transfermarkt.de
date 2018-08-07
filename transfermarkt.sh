
#!/bin/bash

#11 Seiten im transfermarkt.de mit Schiedsrichter Auflistung
#https://www.transfermarkt.de/uefa-champions-league/schiedsrichter/pokalwettbewerb/CL/page/"1-11"?ajax=yw1
#Links zu den verschiedenen Schiedsrichter werden extrahiert.

for i in $(seq 11); do

counter=$((counter+1))

echo "Counter: $counter"
wget -O - "https://www.transfermarkt.de/uefa-champions-league/schiedsrichter/pokalwettbewerb/CL/page/$counter?ajax=yw1" | egrep -o "href=./[^\/]+/profil/schiedsrichter/[0-9]+" | cut -d\" -f2 >> schiri_liste

done

#Extrahierte Links werden nach und nach aufgerufen und Daten extrahiert. (Name, Nationalitaet, Spieltag, Datum, Heimmannschaft,
#Gastmannschaft, Ergebnis, Gelbejarte, Gelbrotekarte, Rotekarte, Elfmeter )

for i in $(<schiri_liste); do

#Name und Schiedsrichter-ID wird aus dem Link extrahiert und in neuen Link eingefügt.
name=$( echo $i | cut -d/ -f2 )
name_id=$( echo $i | cut -d/ -f5 )

#Leistungsdaten des Schiedsrichter XY wird in Datei detail_ansicht.html gespeichert. Aus dieser Datei werden alle weiteren Daten extraiert.
wget -q -O detail_ansicht.html "https://www.transfermarkt.de/$name/leistungsdaten/schiedsrichter/$name_id/plus/1?saison_id=&wettbewerb_id=CL"

#Die Datei detail_ansicht.html wird auf die tatsächlich relevanten Daten gekürzt.
cat detail_ansicht.html | egrep -A 9999 "Diese Seite liefert eine" | egrep -A 9999 '<div class="box">' | egrep -A 9999 '<table>' | egrep -B 9999 "werbung_billboard_btf" | egrep -B 9999 '</table>' | egrep -A 11 '<tr>' | egrep '<td class' > rohdaten

#Anzahl an Spiele die der Schiedsrichter gepfiffen hat wird ermittelt.
anzahl=$( cat detail_ansicht.html | egrep -A 9999 'id=.yw1' | egrep -B 9999 'class=.box' | grep "td class" | head -1 | egrep -o "zentriert..[0-9]+" | head -1 | cut -d\> -f2 )

#counter wird zurück auf 0 gesetzt.
counter=0

#Schleife entsprechend der Anzahl der gepfiffenen Spiele.
for i in $(seq $anzahl); do

#11 relevante Daten pro Spiel, ergibt einen Counter von 11*Spielanzahl. z.B. Counter=77 | tail -11 ergibt die Daten für das 7. Spiel.
counter=$((counter+11))

#Daten des jeweiligen Spiel wird in Datei tmp zwischengespeichert.
cat rohdaten | head -"$counter" | tail -11 > tmp

#Name und Nationalität wird aus Datei detail_ansicht.html extrahiert.
Name=$( cat detail_ansicht.html | egrep -o 'og:title" content="[^"]+' | cut -d\" -f3 | cut -d\- -f1 | sed "s/ ^//g" )
Nationalitaet=$( cat detail_ansicht.html | egrep -A 1 "flaggenrahmen" | grep "alt" | tail -1 | egrep -o "title=.[^\"]+" | cut -d\" -f2 )

#Weitere Daten werden der Datei tmp zum jeweiligen Spiel entnommen. 
Spieltag=$( cat tmp | head -1 | tail -1 | cut -d\> -f 2 | cut -d\< -f1 )
Datum=$(cat tmp | head -2 | tail -1 | cut -d\> -f 2 | cut -d\< -f1 )
Heimmannschaft=$( cat tmp | head -4 | tail -1 | egrep -o '[A-Za-z ]+.\/\a>' | cut -d\< -f1 )
Gastmannschaft=$( cat tmp | head -5 | tail -1 | egrep -o 'alt="[^"]+' | cut -d\" -f2 )
Ergebnis=$(cat tmp | head -7 | tail -1 | egrep -o "[0-9]+:[0-9]+</a>" | cut -d\< -f1)
Gelb=$( cat tmp | head -8 | tail -1 | cut -d\> -f2 | cut -d\< -f1 )
Gelbrot=$( cat tmp | head -9 | tail -1 | cut -d\> -f2 | cut -d\< -f1 )
Rot=$( cat tmp | head -10 | tail -1 | cut -d\> -f2 | cut -d\< -f1 )
Elfmeter=$( cat tmp | head -11 | tail -1 | cut -d\> -f2 | cut -d\< -f1 )


#Daten werden in Dateo daten_neu.csv geschrieben.
echo "$Name,$Nationalitaet,$Spieltag,$Datum,$Heimmannschaft,$Gastmannschaft,$Ergebnis,$Gelb,$Gelbrot,$Rot,$Elfmeter" >> daten_neu.csv

done
done
