import numpy as np
import torch 
import torch.nn as nn 
import torch.optim as optim 

np.random.seed(12)
torch.manual_seed(12)

# pylint: disable=not-callable,no-member
class HyperParameter(object):
    def __init__(self):
        #do not change vocab_size, embeded_size 
        self.vocab_size = 250 
        self.embedded_size = 50
        self.batch_size = 1 

        self.hidden_size = 20
        self.epoch = 30
        self.learning_rate = 0.01
        prefix = './data/input/'
        self.data_path = (prefix+'small.refined.attack', prefix+'small.refined.normal')

class LSTM(nn.Module):
    def __init__(self, param):
        super(LSTM, self).__init__()
        
        self.embedding_layer = nn.Embedding(param.vocab_size,param.embedded_size)
        self.lstm_layer = nn.LSTM(param.embedded_size, param.hidden_size, 1, bidirectional=True)
        self.output_layer = nn.Linear(2*param.hidden_size, param.vocab_size)
        
        self.softmax_layer = nn.Softmax()

    def forward(self, x):

        x = self.embedding_layer(x)
        x = x.view(len(x),1,-1)
        outputs, (hn, cn) = self.lstm_layer(x)
        
        final_output = self.softmax_layer(self.output_layer(outputs[:, -1, :]))    
        return final_output



#convert branch address to int value 
def data_load(data_path):
    br_addr_a = [] #list of converted attack branch address 
    br_addr_n = [] #list of converted normal branch address
    
    alloc = {}
    total = 0
    fpath_a, fpath_n = data_path

    with open(fpath_n) as f:
        for line in f:
            line = line.strip()
            if alloc.get(line)==None:
                total += 1
                alloc[line] = total
            br_addr_n.append(alloc[line])

    with open(fpath_a) as f:
        for line in f:
            line = line.strip()
            if alloc.get(line)==None:
                total += 1
                alloc[line] = total
            br_addr_a.append(alloc[line])

    return torch.tensor(br_addr_a, dtype=torch.long), torch.tensor(br_addr_n, dtype=torch.long)


def to_one_hot(data, param):

    one_hot = torch.zeros(param.vocab_size)
    one_hot[data-1] = 1

    return one_hot



def train(model, device, train_input, train_output, optimizer, criterion, epoch):
    model.train()

    train_input, train_output = train_input.to(device), train_output.to(device)

    optimizer.zero_grad()
    model_output = model(train_input)
    loss = criterion(model_output[-1], train_output)
    loss.backward()
    optimizer.step()

    print('Train epoch: {}, Loss: {:.6f}'.format(epoch, loss.item()))



def test(model, device, test_input, test_output, criterion):
    model.eval()

    with torch.no_grad():
        test_input, test_output = test_input.to(device), test_output.to(device)
        model_output = model(test_input)
        loss = criterion(model_output[-1], test_output)
    
    print('Test Loss: {:.6f}'.format(loss.item()))



if __name__ == '__main__':
    param = HyperParameter()
    epochs = param.epoch
    lr = param.learning_rate 

    data_a, data_n = data_load(param.data_path)

    train_input = data_n[:-1]
    train_output = to_one_hot(data_n[-1], param)

    test_input = data_a[:-1]
    test_output = to_one_hot(data_a[-1], param)

    device = torch.device('cpu')
    model = LSTM(param).to(device)
    optimizer = optim.Adam(params=model.parameters(), lr=param.learning_rate)

    criterion = nn.BCELoss()
    
    for epoch in range(epochs):
        train(model, device, train_input, train_output, optimizer, criterion, epoch)

    test(model, device, test_input, test_output, criterion)
