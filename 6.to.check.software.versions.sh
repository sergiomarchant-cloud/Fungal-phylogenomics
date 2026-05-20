#para revisar la version del software instalado en el equipo
#
#
echo "========================================="
echo "   VERSIONES PARA EL MANUSCRITO"
echo "========================================="
echo -n "Python   : " && python --version 2>&1
echo -n "MAFFT    : " && mafft --version 2>&1
echo -n "trimAl   : " && trimal --version 2>&1
echo -n "FastTree : " && fasttree 2>&1 | head -n 1
echo -n "ASTRAL   : " && astral 2>&1 | grep -i "version" | head -n 1 | awk '{$1=$1;print}'
echo -n "IQ-TREE  : " && iqtree -h 2>&1 | grep -i "version" | head -n 1
echo "========================================="
