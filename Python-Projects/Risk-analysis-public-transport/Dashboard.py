#!/usr/bin/env python
# coding: utf-8

import os
import streamlit as st
import pandas as pd 
import numpy as np 
import matplotlib.pyplot as plt
import seaborn as sns
import seaborn.objects as so
import datetime
import calendar
import locale 
#Page configuration
st.set_page_config(
    page_title="Análise de Risco em Transporte Público",
    page_icon="🚌",
    layout="wide",
    initial_sidebar_state="expanded")

#Load data
df = pd.read_csv('Python-Projects/Risk-analysis-public-transport/data/tfl_bus_safety.csv', sep = ',')

# Sidebar
with st.sidebar:
    st.title("🚌 Análise de Risco em Transporte Público")
    
    year_list = list(df.year.unique())[::-1]
    year_list = year_list + ["Período Completo"]
    selected_year = st.selectbox('Selecione um ano', year_list)
    if selected_year != "Período Completo":
        df_selected_year = df[df.year == selected_year]
    else:
        df_selected_year = df
    color_theme_list = ['pastel','dark', 'flare', 'cividis', 'husl', 'inferno', 'Set2', 'light:#5A9','viridis']
    selected_color_theme = st.selectbox('Escolha uma paleta de cores', color_theme_list)

    opcao_analyse = st.sidebar.selectbox(
    "Tipo de Análise",
    ["Quantidade de Incidentes por Gênero", "Quantidade de Incidentes por Faixa Etária", "Percentual por Tipo de Incidente","Evolução de Incidentes por Mês ao Longo do Tempo","Maior número de incidentes envolvendo pessoas do sexo feminino","Média Mensal de Acidentes","Total de Incidentes Tratados no Local por Gênero","Quantidade de Incidentes com Idosos","Quantidade de incidentes por Operador","Total de Incidentes Ocorridos Envolvendo Ciclistas"]
)
col = st.columns((1.5, 4.5, 2), gap='medium')
    
if opcao_analyse == "Quantidade de Incidentes por Gênero":
    qtd_gen = df_selected_year.groupby('victims_sex').agg({'incident_event_type':'count'}).sort_values(by= 'incident_event_type', ascending= False).reset_index()
    with col[1]:
        st.markdown('### Quantidade de Incidentes por Gênero')
        sns.set_style("whitegrid")
        plot = sns.catplot(
        data=qtd_gen, kind="bar",
        x="victims_sex", y="incident_event_type",
        errorbar="sd", palette=selected_color_theme, alpha=.6, height=6).set_axis_labels("Gênero","Número de incidentes").despine(left=True,bottom= True)
        plt.title("Quantidade de Incidentes por Gênero")
        st.pyplot(plot.fig)
        
if opcao_analyse == "Quantidade de Incidentes por Faixa Etária":
    faixa_etaria = df_selected_year.groupby('victims_age').agg({'victim_category':'count'}).reset_index()
    with col[1]:
        st.markdown('### Quantidade de Incidentes por Faixa Etária')
        sns.set_style("whitegrid")
        plot = sns.catplot(data=faixa_etaria, kind="bar",
                           x="victims_age", y="victim_category",
                           errorbar="sd", palette=selected_color_theme, alpha=.6, height=6).set_axis_labels("Faixa etária","Número de incidentes").despine(left=True,bottom= True)
        plt.title("Quantidade de Incidentes por Faixa Etária")
        st.pyplot(plot.fig)

if opcao_analyse == "Percentual por Tipo de Incidente":
    tipo_evento = df_selected_year.groupby('incident_event_type').agg({'victims_sex':'count'}).reset_index()
    tipo_evento['porcentagem'] = (tipo_evento['victims_sex']/df_selected_year.shape[0])*100
    with col[1]:
        st.markdown('### Percentual por Tipo de Incidente')
        sns.set_style("whitegrid")
        plot = sns.catplot(
                    data=tipo_evento, kind="bar",
                    x="porcentagem", y="incident_event_type",
                    errorbar="sd", palette=selected_color_theme, alpha=.6, height=6
                    ).set_axis_labels("Incidentes(%)","Tipos de Incidentes").despine(left=True,bottom= True)
        plt.title("Percentual por Tipo de Incidente")
        st.pyplot(plot.fig)
        
if opcao_analyse == "Evolução de Incidentes por Mês ao Longo do Tempo":
    df_selected_year['date_of_incident'] = pd.to_datetime(df_selected_year['date_of_incident'], format='%Y-%m-%d')
    df_selected_year['date_of_incident'] = df_selected_year['date_of_incident'].dt.strftime('%Y/%m/%d')
    incidentes_tempo =df_selected_year.groupby('date_of_incident').agg({'incident_event_type':'count'}).reset_index()
    with col[1]:
        st.markdown('### Evolução de Incidentes por Mês ao Longo do Tempo')
        sns.set_style("whitegrid")
        plot = sns.lineplot(data=incidentes_tempo, x='date_of_incident', y='incident_event_type', linewidth = 1)
        plt.plot([incidentes_tempo['date_of_incident'].min(), incidentes_tempo['date_of_incident'].max()], 
         [incidentes_tempo['incident_event_type'].min(), incidentes_tempo['incident_event_type'].max()],
         color='red', linestyle='--')
        plt.title('Evolução de Incidentes por Mês ao Longo do Tempo')
        plt.xlabel('Data')
        plt.ylabel('Número de Incidentes')
        plt.xticks(rotation = 45)
        if selected_year == "Período Completo":
            plt.xticks(incidentes_tempo['date_of_incident'].tolist()[0::6])
        plt.show()
        st.pyplot(plot.get_figure())    
        
if opcao_analyse == "Maior número de incidentes envolvendo pessoas do sexo feminino":
    collision_fem = df_selected_year[(df_selected_year['incident_event_type'] == 'Collision Incident') & (df_selected_year['victims_sex'] == 'Female')] 
    collision_fem_gr =collision_fem.groupby('date_of_incident').agg({'incident_event_type':'count'}).reset_index().sort_values(ascending= True, by = 'date_of_incident')
    with col[1]:
        st.markdown('### Maior número de incidentes envolvendo pessoas do sexo feminino')
        sns.set_style("whitegrid")
        plot = sns.lineplot(data=collision_fem_gr, x='date_of_incident', y='incident_event_type', linewidth = 1)
        plt.title('Maior número de incidentes envolvendo pessoas do sexo feminino')
        plt.xlabel('Data')
        plt.ylabel('Número de Incidentes')
        plt.xticks(rotation = 45)
        if selected_year == "Período Completo":
            plt.xticks(collision_fem_gr['date_of_incident'].tolist()[0::6])
        plt.show()
        plt.title("Maior número de incidentes envolvendo pessoas do sexo feminino")
        st.pyplot(plot.get_figure())

if opcao_analyse == "Média Mensal de Acidentes":
    media_acidentes = df_selected_year.groupby(['victims_age']).agg({'incident_event_type':'count', 'date_of_incident':'nunique'}).reset_index()
    media_acidentes_gr = media_acidentes
    media_acidentes_gr['media'] = media_acidentes['incident_event_type']/media_acidentes['date_of_incident']
    with col[1]:
        st.markdown('### Maior número de incidentes envolvendo pessoas do sexo feminino')
        sns.set_style("whitegrid")
        plot = sns.catplot(
    data=media_acidentes_gr, kind="bar",
    x="victims_age", y="media",
    errorbar="sd", palette=selected_color_theme, alpha=.6, height=6
).set_axis_labels("Faixa etária","Média de incidentes por mês").despine(left=True,bottom= True)
        plt.title("Média Mensal de Acidentes")
        st.pyplot(plot.fig)        
        
if opcao_analyse == "Total de Incidentes Tratados no Local por Gênero":
    injuries_tscene = df_selected_year[(df_selected_year['injury_result_description'] == 'Injuries treated on scene')]
    injuries_tscene_gr = injuries_tscene.groupby('victims_sex').agg({'injury_result_description':'count'}).reset_index()
    with col[1]:
        st.markdown('### Total de Incidentes Tratados no Local por Gênero')
        sns.set_style("whitegrid")
        plot = sns.catplot(
    data=injuries_tscene_gr, kind="bar",
    x="victims_sex", y="injury_result_description",
    errorbar="sd", palette=selected_color_theme, alpha=.8, height=8
).set_axis_labels("Gênero","Total de incidentes").despine(left=True,bottom= True)
        plt.title("Total de Incidentes Tratados no Local por Gênero")
        st.pyplot(plot.fig)        
                
if opcao_analyse == "Quantidade de Incidentes com Idosos":
    locale.setlocale(locale.LC_TIME, '')
    elderly_2017 = df_selected_year[(df_selected_year['victims_age'] == 'Elderly')]
    elderly_2017['month'] = pd.to_datetime(elderly_2017['date_of_incident']).dt.strftime('%B')
    meses_ordenados = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
]
    elderly_2017['ordem_mes'] = pd.Categorical(elderly_2017['month'], categories=meses_ordenados, ordered=True)
    elderly_2017_gr = elderly_2017.groupby('ordem_mes').agg({'victims_sex':'count'}).reset_index().sort_values(by = 'ordem_mes', ascending= True)
    with col[1]:
        st.markdown('### Quantidade de Incidentes com Idosos')
        sns.set_style("whitegrid")
        plot = sns.catplot(
    data=elderly_2017_gr, kind="bar",
    x="victims_sex", y="ordem_mes",
    errorbar="sd", palette=selected_color_theme, alpha=.6, height=6
).set_axis_labels("Quantidade de Incidentes","Data do incidente").despine(left=True,bottom= True)
        plt.title("Quantidade de Incidentes com Idosos")
        st.pyplot(plot.fig)             
        
if opcao_analyse == "Quantidade de incidentes por Operador":
    operator = df_selected_year.groupby(['operator','date_of_incident']).agg({'incident_event_type':'count'}).reset_index()
    with col[1]:
        st.markdown('### Quantidade de incidentes por Operador')
        sns.set_style("whitegrid")
        plt.figure(figsize = (16,10))
        plot = sns.histplot(df, x="date_of_incident", hue = 'operator', palette= selected_color_theme)
        plt.title("Total de Incidentes Tratados no Local por Gênero")
        sns.move_legend(loc='best', bbox_to_anchor=(1,1), obj=sns.histplot(df, x="date_of_incident", hue = 'operator', palette= sns.color_palette('husl',25)))
        plt.xticks(rotation = 45)
        plt.title('Quantidade de incidentes por Operador')
        plt.xlabel('Data do incidente')
        plt.ylabel('Quantidade de incidentes')
        plt.show()
        st.pyplot(plot.get_figure())           
        
if opcao_analyse == "Total de Incidentes Ocorridos Envolvendo Ciclistas":
    bike = df_selected_year[df_selected_year['victim_category'] == 'Cyclist']
    bike_gr = bike.groupby('incident_event_type').agg({'victim_category':'count'}).reset_index()
    with col[1]:
        st.markdown('### Total de Incidentes Ocorridos Envolvendo Ciclistas')
        sns.set_style("whitegrid")
        plot = sns.catplot(
    data=bike_gr, kind="bar",
    x="incident_event_type", y="victim_category",
    errorbar="sd", palette=selected_color_theme, alpha=.8, height=8
).set_axis_labels("Tipo de Incidente","Total de incidentes").despine(left=True,bottom= True)
        plt.title("Total de Incidentes Ocorridos Envolvendo Ciclistas")
        st.pyplot(plot.fig)   
        