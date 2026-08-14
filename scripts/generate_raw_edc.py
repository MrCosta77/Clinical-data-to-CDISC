import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random
import os

# Configurações do Ensaio Clínico (Simulação do CDISC Pilot)
NUM_PATIENTS = 50
SITES = ['701', '702', '703', '704']
START_DATE = datetime(2023, 1, 1)

def generate_patients():
    patients = []
    arms = ['Placebo', 'Active Drug 50mg']
    for i in range(1, NUM_PATIENTS + 1):
        site = random.choice(SITES)
        subject_id = f"{site}-{i:03d}"
        
        age_days = random.randint(65*365, 85*365)
        dob = START_DATE - timedelta(days=age_days)
        consent_date = START_DATE + timedelta(days=random.randint(0, 30))
        
        # Simulating Enrollment vs Randomization (10% Screen Failure)
        is_randomized = random.random() > 0.10 
        planned_arm = random.choice(arms) if is_randomized else 'Not Randomized'
        
        patients.append({
            'SUBJ_ID': subject_id,
            'SITE': site,
            'BRTH_DT': dob.strftime('%d/%m/%Y'),
            'GENDER': random.choice(['M', 'F', 'Male', 'Female']),
            'RACE_TXT': random.choices(['White', 'Black', 'Asian', 'Other'], weights=[0.7, 0.15, 0.1, 0.05])[0],
            'ICF_DAT': consent_date.strftime('%Y-%m-%d'),
            'RANDOMIZED_ARM': planned_arm,
            'ENROLLED': 'Y'
        })
    return pd.DataFrame(patients)

def generate_vitals(patients_df):
    vitals = []
    for subj in patients_df['SUBJ_ID']:
        for visit_num in [1, 2, 3]: # Screening, Baseline, Semana 4
            visit_date = START_DATE + timedelta(days=30 * visit_num + random.randint(-2, 2))
            vitals.append({
                'PT_ID': subj, # Nome de ID inconsistente intencionalmente
                'VISIT': f'Visit {visit_num}',
                'VS_DATE': visit_date.strftime('%d-%b-%Y'),
                'SYS_BP': random.randint(110, 160),
                'DIA_BP': random.randint(70, 100),
                'HR_BPM': random.randint(60, 100),
                'WEIGHT_KG': round(random.uniform(55.0, 95.0), 1)
            })
    return pd.DataFrame(vitals)

def generate_adverse_events(patients_df):
    aes = []
    ae_dictionary = ['Headache', 'Nausea', 'Dizziness', 'Insomnia', 'Fatigue', 'Application site erythema']
    
    # Nem todos os doentes têm EAs
    ae_patients = patients_df.sample(frac=0.6)
    
    for subj in ae_patients['SUBJ_ID']:
        num_aes = random.randint(1, 3)
        for _ in range(num_aes):
            start_dt = START_DATE + timedelta(days=random.randint(10, 90))
            end_dt = start_dt + timedelta(days=random.randint(1, 14))
            aes.append({
                'ID': subj,
                'AE_TERM': random.choice(ae_dictionary),
                'START': start_dt.strftime('%d/%m/%Y'),
                'END': end_dt.strftime('%d/%m/%Y') if random.random() > 0.1 else '', # 10% de EAs sem data de fim (Ongoing)
                'SEV': random.choice(['MILD', 'MODERATE', 'SEVERE']),
                'RELATED': random.choice(['Y', 'N'])
            })
    return pd.DataFrame(aes)

if __name__ == "__main__":
    print("🧪 A gerar dados EDC brutos para o estudo clínico...")
    
    # Criar pasta se não existir
    os.makedirs('data/raw', exist_ok=True)
    
    df_dm = generate_patients()
    df_vs = generate_vitals(df_dm)
    df_ae = generate_adverse_events(df_dm)
    
    df_dm.to_csv('data/raw/raw_demog.csv', index=False)
    df_vs.to_csv('data/raw/raw_vitals.csv', index=False)
    df_ae.to_csv('data/raw/raw_ae.csv', index=False)
    
    print("✅ Sucesso! Ficheiros gerados na pasta 'data/raw/':")
    print(f" - raw_demog.csv ({len(df_dm)} registos)")
    print(f" - raw_vitals.csv ({len(df_vs)} registos)")
    print(f" - raw_ae.csv ({len(df_ae)} registos)")