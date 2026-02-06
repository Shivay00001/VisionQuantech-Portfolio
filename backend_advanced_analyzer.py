"""
Advanced Data Analyzer - Production-grade DSA Engine
Data profiling, cleaning, quality scoring, and feature engineering
"""
import pandas as pd
import numpy as np
from scipy import stats
from sklearn.preprocessing import StandardScaler, MinMaxScaler, LabelEncoder
from sklearn.decomposition import PCA
from sklearn.ensemble import IsolationForest
from typing import Dict, List, Tuple, Any, Optional
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

class AdvancedAnalyzer:
    """
    Comprehensive data analysis and preprocessing engine
    Inspired by production data science workflows
    """
    
    def __init__(self, df: pd.DataFrame):
        """Initialize with DataFrame"""
        self.df = df.copy()
        self.original_df = df.copy()
        self.profile = {}
        self.cleaning_report = {}
    
    def comprehensive_profiling(self) -> Dict[str, Any]:
        """
        Generate comprehensive data profile
        
        Returns:
            Complete profiling report
        """
        logger.info("Starting comprehensive data profiling...")
        
        profile = {
            'basic_info': self._get_basic_info(),
            'column_analysis': self._analyze_columns(),
            'missing_data': self._analyze_missing_data(),
            'duplicates': self._analyze_duplicates(),
            'statistical_summary': self._statistical_summary(),
            'correlation_analysis': self._correlation_analysis(),
            'outlier_detection': self._detect_outliers(),
            'data_quality_score': self._calculate_quality_score(),
            'timestamp': datetime.utcnow().isoformat()
        }
        
        self.profile = profile
        logger.info("Profiling completed successfully")
        return profile
    
    def _get_basic_info(self) -> Dict[str, Any]:
        """Basic dataset information"""
        return {
            'rows': len(self.df),
            'columns': len(self.df.columns),
            'total_cells': self.df.size,
            'memory_usage_mb': self.df.memory_usage(deep=True).sum() / (1024 ** 2),
            'dtypes': self.df.dtypes.value_counts().to_dict()
        }
    
    def _analyze_columns(self) -> Dict[str, Dict[str, Any]]:
        """Detailed column-level analysis"""
        column_stats = {}
        
        for col in self.df.columns:
            dtype = str(self.df[col].dtype)
            
            stats_dict = {
                'dtype': dtype,
                'null_count': int(self.df[col].isnull().sum()),
                'null_percentage': float(self.df[col].isnull().sum() / len(self.df) * 100),
                'unique_count': int(self.df[col].nunique()),
                'unique_percentage': float(self.df[col].nunique() / len(self.df) * 100)
            }
            
            # Numeric column stats
            if pd.api.types.is_numeric_dtype(self.df[col]):
                stats_dict.update({
                    'mean': float(self.df[col].mean()) if not self.df[col].isnull().all() else None,
                    'median': float(self.df[col].median()) if not self.df[col].isnull().all() else None,
                    'std': float(self.df[col].std()) if not self.df[col].isnull().all() else None,
                    'min': float(self.df[col].min()) if not self.df[col].isnull().all() else None,
                    'max': float(self.df[col].max()) if not self.df[col].isnull().all() else None,
                    'zeros': int((self.df[col] == 0).sum())
                })
            
            # Categorical column stats
            else:
                value_counts = self.df[col].value_counts().head(10)
                stats_dict.update({
                    'top_values': value_counts.to_dict(),
                    'mode': str(self.df[col].mode()[0]) if not self.df[col].mode().empty else None
                })
            
            column_stats[col] = stats_dict
        
        return column_stats
    
    def _analyze_missing_data(self) -> Dict[str, Any]:
        """Analyze missing data patterns"""
        missing_counts = self.df.isnull().sum()
        missing_percentages = (missing_counts / len(self.df) * 100).round(2)
        
        return {
            'total_missing': int(missing_counts.sum()),
            'percentage_missing': float(missing_counts.sum() / self.df.size * 100),
            'columns_with_missing': missing_counts[missing_counts > 0].to_dict(),
            'missing_percentages': missing_percentages[missing_percentages > 0].to_dict(),
            'completely_empty_columns': list(self.df.columns[self.df.isnull().all()])
        }
    
    def _analyze_duplicates(self) -> Dict[str, Any]:
        """Analyze duplicate rows"""
        duplicates = self.df.duplicated()
        
        return {
            'total_duplicates': int(duplicates.sum()),
            'duplicate_percentage': float(duplicates.sum() / len(self.df) * 100),
            'unique_rows': int(len(self.df) - duplicates.sum())
        }
    
    def _statistical_summary(self) -> Dict[str, Any]:
        """Statistical summary for numeric and categorical columns"""
        numeric_cols = self.df.select_dtypes(include=[np.number]).columns.tolist()
        categorical_cols = self.df.select_dtypes(include=['object', 'category']).columns.tolist()
        
        summary = {
            'numeric_columns': len(numeric_cols),
            'categorical_columns': len(categorical_cols),
        }
        
        if numeric_cols:
            summary['numeric_summary'] = self.df[numeric_cols].describe().to_dict()
        
        if categorical_cols:
            cat_summary = {}
            for col in categorical_cols[:10]:  # Limit to first 10 categorical columns
                cat_summary[col] = {
                    'unique': int(self.df[col].nunique()),
                    'top': str(self.df[col].mode()[0]) if not self.df[col].mode().empty else None,
                    'freq': int(self.df[col].value_counts().iloc[0]) if len(self.df[col]) > 0 else 0
                }
            summary['categorical_summary'] = cat_summary
        
        return summary
    
    def _correlation_analysis(self) -> Dict[str, Any]:
        """Correlation analysis for numeric columns"""
        numeric_cols = self.df.select_dtypes(include=[np.number]).columns
        
        if len(numeric_cols) < 2:
            return {'message': 'Insufficient numeric columns for correlation analysis'}
        
        corr_matrix = self.df[numeric_cols].corr()
        
        # Find high correlations
        high_corr = []
        for i in range(len(corr_matrix.columns)):
            for j in range(i+1, len(corr_matrix.columns)):
                corr_val = corr_matrix.iloc[i, j]
                if abs(corr_val) > 0.7:  # Threshold for high correlation
                    high_corr.append({
                        'col1': corr_matrix.columns[i],
                        'col2': corr_matrix.columns[j],
                        'correlation': float(corr_val)
                    })
        
        return {
            'correlation_matrix': corr_matrix.to_dict(),
            'high_correlations': high_corr,
            'correlation_count': len(high_corr)
        }
    
    def _detect_outliers(self, threshold: float = 3.0) -> Dict[str, Any]:
        """Detect outliers using IQR and Z-score methods"""
        numeric_cols = self.df.select_dtypes(include=[np.number]).columns
        outlier_report = {}
        
        for col in numeric_cols:
            col_data = self.df[col].dropna()
            
            if len(col_data) == 0:
                continue
            
            # IQR method
            Q1 = col_data.quantile(0.25)
            Q3 = col_data.quantile(0.75)
            IQR = Q3 - Q1
            iqr_outliers = ((col_data < (Q1 - 1.5 * IQR)) | (col_data > (Q3 + 1.5 * IQR))).sum()
            
            # Z-score method
            z_scores = np.abs(stats.zscore(col_data))
            z_outliers = (z_scores > threshold).sum()
            
            outlier_report[col] = {
                'iqr_outliers': int(iqr_outliers),
                'zscore_outliers': int(z_outliers),
                'outlier_percentage': float(iqr_outliers / len(col_data) * 100)
            }
        
        return outlier_report
    
    def _calculate_quality_score(self) -> Dict[str, float]:
        """Calculate overall data quality score"""
        # Completeness score (inverse of missing data)
        completeness = 1 - (self.df.isnull().sum().sum() / self.df.size)
        
        # Uniqueness score (inverse of duplicates)
        uniqueness = 1 - (self.df.duplicated().sum() / len(self.df))
        
        # Consistency score (based on data types)
        consistency = 1.0  # Simplified - could be enhanced
        
        # Overall quality score (weighted average)
        overall = (completeness * 0.4 + uniqueness * 0.4 + consistency * 0.2)
        
        return {
            'completeness': round(float(completeness), 3),
            'uniqueness': round(float(uniqueness), 3),
            'consistency': round(float(consistency), 3),
            'overall': round(float(overall), 3)
        }
    
    def auto_clean_data(self, strategy: str = 'auto') -> Tuple[pd.DataFrame, Dict[str, Any]]:
        """
        Automatically clean data based on strategy
        
        Args:
            strategy: 'auto', 'aggressive', or 'conservative'
        
        Returns:
            Cleaned DataFrame and cleaning report
        """
        logger.info(f"Starting auto-clean with strategy: {strategy}")
        
        df_cleaned = self.df.copy()
        report = {
            'strategy': strategy,
            'actions': [],
            'rows_before': len(df_cleaned),
            'rows_after': 0,
            'columns_before': len(df_cleaned.columns),
            'columns_after': 0
        }
        
        # Remove completely empty columns
        empty_cols = df_cleaned.columns[df_cleaned.isnull().all()].tolist()
        if empty_cols:
            df_cleaned = df_cleaned.drop(columns=empty_cols)
            report['actions'].append(f"Removed {len(empty_cols)} empty columns")
        
        # Handle duplicates
        if strategy in ['auto', 'aggressive']:
            dup_count = df_cleaned.duplicated().sum()
            if dup_count > 0:
                df_cleaned = df_cleaned.drop_duplicates()
                report['actions'].append(f"Removed {dup_count} duplicate rows")
        
        # Handle missing values
        if strategy == 'aggressive':
            # Drop rows with any missing values
            df_cleaned = df_cleaned.dropna()
            report['actions'].append("Dropped all rows with missing values")
        
        elif strategy == 'auto':
            # Drop columns with >50% missing values
            thresh = len(df_cleaned) * 0.5
            df_cleaned = df_cleaned.dropna(axis=1, thresh=thresh)
            
            # Fill numeric columns with median
            numeric_cols = df_cleaned.select_dtypes(include=[np.number]).columns
            for col in numeric_cols:
                if df_cleaned[col].isnull().any():
                    df_cleaned[col].fillna(df_cleaned[col].median(), inplace=True)
            
            # Fill categorical columns with mode
            cat_cols = df_cleaned.select_dtypes(include=['object']).columns
            for col in cat_cols:
                if df_cleaned[col].isnull().any():
                    mode_val = df_cleaned[col].mode()[0] if not df_cleaned[col].mode().empty else 'Unknown'
                    df_cleaned[col].fillna(mode_val, inplace=True)
            
            report['actions'].append("Handled missing values (median/mode imputation)")
        
        # Handle outliers (only in aggressive mode)
        if strategy == 'aggressive':
            numeric_cols = df_cleaned.select_dtypes(include=[np.number]).columns
            for col in numeric_cols:
                Q1 = df_cleaned[col].quantile(0.25)
                Q3 = df_cleaned[col].quantile(0.75)
                IQR = Q3 - Q1
                df_cleaned = df_cleaned[
                    (df_cleaned[col] >= Q1 - 1.5 * IQR) & 
                    (df_cleaned[col] <= Q3 + 1.5 * IQR)
                ]
            report['actions'].append("Removed outliers using IQR method")
        
        report['rows_after'] = len(df_cleaned)
        report['columns_after'] = len(df_cleaned.columns)
        report['rows_removed'] = report['rows_before'] - report['rows_after']
        report['columns_removed'] = report['columns_before'] - report['columns_after']
        
        self.df = df_cleaned
        self.cleaning_report = report
        
        logger.info(f"Cleaning completed: {report['rows_removed']} rows, {report['columns_removed']} columns removed")
        return df_cleaned, report
    
    def feature_engineering(self) -> Dict[str, Any]:
        """
        Advanced feature engineering
        
        Returns:
            Feature engineering report and transformed data
        """
        logger.info("Starting feature engineering...")
        
        report = {
            'encoders': {},
            'scalers': {},
            'pca': {},
            'anomalies': {}
        }
        
        df_featured = self.df.copy()
        
        # Label encoding for categorical variables
        cat_cols = df_featured.select_dtypes(include=['object']).columns
        for col in cat_cols:
            le = LabelEncoder()
            df_featured[f'{col}_encoded'] = le.fit_transform(df_featured[col].astype(str))
            report['encoders'][col] = {
                'classes': le.classes_.tolist()[:20],  # Limit to 20
                'n_classes': len(le.classes_)
            }
        
        # Scaling numeric features
        numeric_cols = df_featured.select_dtypes(include=[np.number]).columns
        if len(numeric_cols) > 0:
            scaler = StandardScaler()
            scaled_data = scaler.fit_transform(df_featured[numeric_cols])
            for i, col in enumerate(numeric_cols):
                df_featured[f'{col}_scaled'] = scaled_data[:, i]
            
            report['scalers']['standard'] = {
                'features': numeric_cols.tolist(),
                'mean': scaler.mean_.tolist(),
                'std': scaler.scale_.tolist()
            }
        
        # PCA for dimensionality reduction
        if len(numeric_cols) > 2:
            pca = PCA(n_components=min(3, len(numeric_cols)))
            pca_data = pca.fit_transform(df_featured[numeric_cols].fillna(0))
            
            for i in range(pca_data.shape[1]):
                df_featured[f'pca_{i+1}'] = pca_data[:, i]
            
            report['pca'] = {
                'n_components': pca.n_components_,
                'explained_variance_ratio': pca.explained_variance_ratio_.tolist(),
                'cumulative_variance': np.cumsum(pca.explained_variance_ratio_).tolist()
            }
        
        # Anomaly detection
        if len(numeric_cols) > 0 and len(df_featured) > 10:
            iso_forest = IsolationForest(contamination=0.1, random_state=42)
            anomalies = iso_forest.fit_predict(df_featured[numeric_cols].fillna(0))
            df_featured['anomaly'] = anomalies
            
            report['anomalies'] = {
                'total_anomalies': int((anomalies == -1).sum()),
                'anomaly_percentage': float((anomalies == -1).sum() / len(anomalies) * 100)
            }
        
        logger.info("Feature engineering completed")
        return report
    
    def get_cleaned_data(self) -> pd.DataFrame:
        """Get cleaned DataFrame"""
        return self.df
    
    def get_profile(self) -> Dict[str, Any]:
        """Get profiling report"""
        return self.profile
    
    def get_cleaning_report(self) -> Dict[str, Any]:
        """Get cleaning report"""
        return self.cleaning_report
