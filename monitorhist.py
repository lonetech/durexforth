import pandas as pd

df = pd.read_fwf("build/monitor.log", colspecs=[(0,3), (3,7), (68,100)], names=['t','addr','cycle'], header=None)
df = df.query('t==".C:"').drop('t', axis='columns')
df.addr = df.addr.map(lambda x: int(x,16))
df['cycles'] = df.cycle.diff()
df = df.dropna().convert_dtypes()

# Why does the index go object here?
cum = df.groupby('addr').cycles.sum()
cum.index = cum.index.map(int)

labels = pd.read_table('forth.lbl', header=None, usecols=[1,2], names=['t', 'addr', 'name'], sep=' ')
labels.addr = labels.addr.map(lambda x: int(x,16)).convert_dtypes()
labels = labels.set_index('addr').sort_index()

try:
    where = pd.merge_asof(cum.sort_index(), labels, left_index=True, right_index=True)
    print(where.groupby('name').sum().sort_values('cycles').tail(50))
except:
    pass

