import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random
import os

def generate_extras():
    print("🧪 Reading original population and generating new domains...")
    
    try:
        df_dm = pd.read_csv('data/raw/raw_demog.csv')
    except FileNotFoundError:
        print("❌ Error: Could not find data/raw/raw_demog.csv. Please run the first script first.")
        return

    ex_records = []
    lb_records = []
    cm_records = []
    mh_records = []
    eg_records = []
    
    cm_meds = ['Paracetamol', 'Ibuprofen', 'Omeprazole', 'Lisinopril', 'Atorvastatin', 'Aspirin']
    lab_tests = ['Glucose', 'Hemoglobin', 'ALT', 'AST']
    mh_conditions = ['Hypertension', 'Type 2 Diabetes', 'Asthma', 'Depression', 'Hyperlipidemia', 'Osteoarthritis']
    eg_tests = ['Heart Rate', 'QT Duration', 'RR Duration']
    
    for _, row in df_dm.iterrows():
        if row.get('RANDOMIZED_ARM') == 'Not Randomized':
            continue
        
        subj_id = row['SUBJ_ID']
        # Use consent date as the baseline for events
        try:
            start_base = datetime.strptime(row['ICF_DAT'], '%Y-%m-%d')
        except:
            start_base = datetime(2023, 1, 15) # Fallback

        # ---------------------------------------------------------
        # 1. GENERATE EXPOSURE (Study Drug)
        # ---------------------------------------------------------
        if random.random() < 0.05:  
            trt_arm = 'Placebo' if row['RANDOMIZED_ARM'] == 'Active Drug 50mg' else 'Active Drug 50mg'
        else:
            trt_arm = row['RANDOMIZED_ARM'] # 95% recebe o tratamento correto
            
        dose_start = start_base + timedelta(days=random.randint(1, 5))
        
        # 15% of patients drop out early
        days_on_drug = random.randint(10, 30) if random.random() < 0.15 else 84 
        dose_end = dose_start + timedelta(days=days_on_drug)
        
        ex_records.append({
            'PATIENT': subj_id,
            'TREATMENT': trt_arm,
            'DOSE': 50 if trt_arm == 'Active Drug 50mg' else 0,
            'UNIT': 'mg',
            'START_DATE': dose_start.strftime('%d/%m/%Y'),
            'END_DATE': dose_end.strftime('%d/%m/%Y') if random.random() > 0.05 else '' 
        })

        # ---------------------------------------------------------
        # 2. GENERATE LABORATORY (3 Visits)
        # ---------------------------------------------------------
        for visit_num in [1, 2, 3]:
            if visit_num == 1:
                lab_date = start_base + timedelta(days=random.randint(-3, 0))
            else:
                lab_date = start_base + timedelta(days=30 * (visit_num - 1) + random.randint(-5, 5))
            
            for test in lab_tests:
                if test == 'Glucose':
                    res = round(random.uniform(70.0, 120.0), 1)
                    unit = random.choice(['mg/dL', 'MG/DL'])
                elif test == 'Hemoglobin':
                    res = round(random.uniform(11.0, 16.5), 1)
                    unit = 'g/dL'
                else: # ALT / AST
                    res = random.randint(10, 45)
                    unit = 'U/L'
                    
                lb_records.append({
                    'SUBJ': subj_id,
                    'VISIT_NAM': f'Visit {visit_num}',
                    'LAB_DAT': lab_date.strftime('%Y-%m-%d'),
                    'TEST_NAME': test,
                    'RESULT': res,
                    'UNIT': unit
                })
        
        # ---------------------------------------------------------
        # 3. GENERATE CONCOMITANT MEDICATIONS (CM)
        # ---------------------------------------------------------
        num_cm = random.randint(0, 3) 
        for _ in range(num_cm):
            cm_start = start_base - timedelta(days=random.randint(10, 365)) 
            cm_end = start_base + timedelta(days=random.randint(10, 80)) if random.random() > 0.4 else ''
            
            cm_records.append({
                'SUBJECT': subj_id,
                'MEDICATION': random.choice(cm_meds),
                'DOSE': random.choice(['10 mg', '20 mg', '500 mg', '1000 mg']),
                'START_DT': cm_start.strftime('%d/%m/%Y'),
                'END_DT': cm_end.strftime('%d/%m/%Y') if cm_end else '',
                'ONGOING': 'Y' if not cm_end else 'N'
            })

        # ---------------------------------------------------------
        # 4. GENERATE MEDICAL HISTORY (MH)
        # ---------------------------------------------------------
        num_mh = random.randint(0, 2)
        for _ in range(num_mh):
            # Histórico médico acontece algures entre 1 a 15 anos antes do ensaio
            mh_start = start_base - timedelta(days=random.randint(365, 5000))
            
            mh_records.append({
                'SUBJECT': subj_id,
                'CONDITION': random.choice(mh_conditions),
                'DIAGNOSIS_DATE': mh_start.strftime('%Y-%m-%d')
            })

        # ---------------------------------------------------------
        # 5. GENERATE ECG TEST RESULTS (EG)
        # ---------------------------------------------------------
        # Assumimos um ECG na visita de Baseline
        eg_date = start_base + timedelta(days=random.randint(-3, 0))
        for test in eg_tests:
            if test == 'Heart Rate':
                res = random.randint(60, 100)
                unit = 'beats/min'
            elif test == 'QT Duration':
                res = random.randint(350, 450)
                unit = 'msec'
            else: # RR Duration
                res = random.randint(600, 1000)
                unit = 'msec'
                
            eg_records.append({
                'SUBJECT': subj_id,
                'TEST_NAME': test,
                'RESULT': res,
                'UNIT': unit,
                'DATE': eg_date.strftime('%Y-%m-%d')
            })

    # Save files
    pd.DataFrame(ex_records).to_csv('data/raw/raw_exposure.csv', index=False)
    pd.DataFrame(lb_records).to_csv('data/raw/raw_lab.csv', index=False)
    pd.DataFrame(cm_records).to_csv('data/raw/raw_conmeds.csv', index=False)
    pd.DataFrame(mh_records).to_csv('data/raw/raw_mh.csv', index=False)
    pd.DataFrame(eg_records).to_csv('data/raw/raw_ecg.csv', index=False)
    
    print("✅ Success! Extra files generated in the 'data/raw/' folder:")
    print(f" - raw_exposure.csv ({len(ex_records)} records)")
    print(f" - raw_lab.csv ({len(lb_records)} records)")
    print(f" - raw_conmeds.csv ({len(cm_records)} records)")
    print(f" - raw_mh.csv ({len(mh_records)} records)")
    print(f" - raw_ecg.csv ({len(eg_records)} records)")

if __name__ == "__main__":
    generate_extras()