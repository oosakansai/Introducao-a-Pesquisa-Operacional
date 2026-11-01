# CONJUNTOS ----------------------------------------------------------------------------

set P;         # Professores
set T;         # Turmas
set M;         # Matérias
set D;         # Dias
set H;         # Horários dentro do dia

set Mt{T} within M;          # Matérias que a turma t precisa cursar
set Mp{P} within M;          # Matérias que o professor p pode ministrar
set Pm{M} within P;          # Professores aptos a ministrar a matéria m
set Mpt{P,T} within M;       # Matérias do professor p na turma t

set S;                       # Slots (dia + horário), equivale a um quadrinho na grade
set St{T} within S;          # Slots possíveis da turma t
set Sd{D} within S;          # Slots do dia d
set Sp{P} within S;          # Slots de preferência/disponibilidade do professor p
set Spt{P,T} within S;       # Slots possíveis do professor p na turma t




# PARÂMETROS ----------------------------------------------------------------------------

param a{t in T, m in Mt[t]};              # para cada turma em T, a quantidade de aulas da de cada m em Mt[t] que devem ser ministradas
param atd{t in T, d in D};                # Nº máximo de aulas da turma t no dia d
param lmin{P};                            # Carga horária mínima é a mesma para todos
param lmax{P};                            # Carga horária máxima é a mesma para todos
param nmax{P,T,D};                        # Máximo de aulas do professor p na turma t no dia d

param b{P,M,T} default 0;                 # Benefício de alocar um professor p, ensinando materia m, para turma t.
param h{M,T,S} default 0;                 # Beneficio de alocar uma materia m na turma t em um slot s.
param alpha1 >= 0;                        # Peso da penalidade de carga mínima
param alpha2 >= 0;                        # Peso da penalidade de aulas diárias excessivas





# VARIÁVEIS ------------------------------------------------------------------------------------------

var x{p in P, m in Mpt[p,t], t in T, s in Spt[p,t]} binary;
var y{P} >= 0 integer;                    # Aulas abaixo da carga mínima
var z{p in P, m in Mpt[p,t], t in T} binary;
var u{p in P, t in T, d in D} >= 0 integer;






# FUNÇÃO OBJETIVO -------------------------------------------------------------------------------------------------------

maximize BeneficioTotal:
    sum{p in P, t in T, m in Mpt[p,t], s in Spt[p,t]} b[p,m,t] * h[m,t,s] * x[p,m,t,s]
  - alpha1 * sum{p in P} y[p]
  - alpha2 * sum{p in P, t in T, d in D} u[p,t,d];






# RESTRIÇÕES ------------------------------------------------------------------------------------

# (2) Sem conflito de horário na turma
subject to SemConflitoTurma{t in T, s in St[t]}:
    sum{p in P, m in Mpt[p,t]: s in Spt[p,t]} x[p,m,t,s] <= 1;

# (3) Sem conflito de horário do professor
subject to SemConflitoProfessor{p in P, s in Sp[p]}:
    sum{t in T, m in Mpt[p,t]: s in Spt[p,t]} x[p,m,t,s] <= 1;

# (4) Carga horária do professor (Soft para carga mínima)
subject to CargaHoraria{p in P}:
    lmin[p] - y[p] <= sum{t in T, m in Mpt[p,t], s in Spt[p,t]} x[p,m,t,s] <= lmax[p];

# (5) Atender o número exato de aulas de cada matéria
subject to AulasNecessarias{t in T, m in Mt[t]}:
    sum{p in Pm[m], s in Spt[p,t]} x[p,m,t,s] = a[t,m];

# (6) Limite de aulas por dia na turma
subject to AulasPorDia{t in T, d in D}:
    sum{p in P, m in Mpt[p,t], s in Sd[d] inter Spt[p,t]} x[p,m,t,s] <= atd[t,d];

# (7) Limite de aulas do professor na mesma turma no mesmo dia (Soft)
subject to LimiteAulasDia{p in P, t in T, d in D}:
    sum{m in Mpt[p,t], s in Sd[d] inter Spt[p,t]} x[p,m,t,s] <= nmax[p,t,d] + u[p,t,d];

# (8) e (9) Um único professor por matéria-turma
subject to UmProfessorPorMateria{t in T, m in Mt[t]}:
    sum{p in Pm[m]} z[p,m,t] <= 1;

subject to LigaXZ{p in P, t in T, m in Mpt[p,t], s in Spt[p,t]}:
    x[p,m,t,s] <= z[p,m,t];