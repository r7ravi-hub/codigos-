document.addEventListener('DOMContentLoaded', function() {
    // ========= ELEMENTOS DOM =========
    const workflowItems = document.querySelectorAll('.workflow-item');
    const workflowTitle = document.querySelector('.selected-workflow-name');
    const listsContainer = document.querySelector('.lists-container');
    let selectedWorkflowId = null;

    // ========= ELEMENTOS MODAIS =========
    const listModal = document.getElementById('createListModal');
    const listNameInput = listModal.querySelector('#listName');
    const cardModal = document.getElementById('createCardModal');
    const cardNameInput = cardModal.querySelector('#cardName');
    let selectedListId = null;

    // Inicializa o modal de criar workflow
    const createWorkflowModal = document.getElementById('createWorkflowModal');
    const createWorkflowBtn = document.querySelector('.create-btn');
    const workflowNameInput = document.getElementById('workflowName');

    // Abre o modal ao clicar no botão
    createWorkflowBtn.addEventListener('click', () => {
        createWorkflowModal.classList.add('active');
        workflowNameInput.value = ''; // Limpa o input
        workflowNameInput.focus();
    });

    // Adiciona os eventos aos botões do modal
    createWorkflowModal.querySelector('.confirm-btn').addEventListener('click', async () => {
        const nome = workflowNameInput.value.trim();
        if (!nome) {
            alert('Por favor, digite um nome para o workflow');
            return;
        }

        try {
            const formData = new FormData();
            formData.append('action', 'create_workflow');
            formData.append('nome', nome);

            const response = await fetch('index.php', {
                method: 'POST',
                body: formData
            });

            const data = await response.json();
            if (data.success) {
                createWorkflowModal.classList.remove('active');
                window.location.reload();
            } else {
                throw new Error(data.message || 'Erro ao criar workflow');
            }
        } catch (error) {
            alert(error.message);
        }
    });

    // Fecha o modal ao clicar em cancelar
    createWorkflowModal.querySelector('.cancel-btn').addEventListener('click', () => {
        createWorkflowModal.classList.remove('active');
    });

    // E adicione esta função helper no início do seu arquivo script.js
function isExpired(dateString) {
    const endTime = new Date(dateString).getTime();
    return Date.now() > endTime;
}


    // ========= FUNÇÕES MODAIS =========
    function openListModal() {
        const modal = document.getElementById('createListModal');
        const input = modal.querySelector('#listName');
        const confirmBtn = modal.querySelector('.confirm-btn');
        const cancelBtn = modal.querySelector('.cancel-btn');

        // Remove handlers antigos
        const newConfirmBtn = confirmBtn.cloneNode(true);
        const newCancelBtn = cancelBtn.cloneNode(true);
        confirmBtn.parentNode.replaceChild(newConfirmBtn, confirmBtn);
        cancelBtn.parentNode.replaceChild(newCancelBtn, cancelBtn);

        modal.classList.add('active');
        input.value = '';
        input.focus();

        // Adiciona novos handlers
        newConfirmBtn.addEventListener('click', async () => {
            const nome = input.value.trim();
            if (!nome) {
                alert('Por favor, digite um nome para a lista');
                return;
            }

            try {
                const formData = new FormData();
                formData.append('action', 'create_list');
                formData.append('nome', nome);
                formData.append('workflow_id', selectedWorkflowId);

                const response = await fetch('index.php', {
                    method: 'POST',
                    body: formData
                });

                const data = await response.json();
                if (data.success) {
                    modal.classList.remove('active');
                    console.log('Lista criada, recarregando página...');
                    // Força um reload da página
                    window.location.reload();
                } else {
                    throw new Error(data.message || 'Erro ao criar lista');
                }
            } catch (error) {
                console.error('Erro ao criar lista:', error);
                alert(error.message);
            }
        });

        newCancelBtn.addEventListener('click', () => {
            modal.classList.remove('active');
        });
    }

    function closeListModal() {
        const modal = document.getElementById('createListModal');
        modal.classList.remove('active');
        modal.querySelector('#listName').value = '';
    }

    function openCardModal(listId = null, parentId = null) {
        if (!listId) {
            console.error('ListId é obrigatório');
            return;
        }
        
        const modal = document.getElementById('createCardModal');
        const input = modal.querySelector('#cardName');
        const confirmBtn = modal.querySelector('.confirm-btn');
        const cancelBtn = modal.querySelector('.cancel-btn');
        
        // Remove handlers antigos
        const newConfirmBtn = confirmBtn.cloneNode(true);
        const newCancelBtn = cancelBtn.cloneNode(true);
        confirmBtn.parentNode.replaceChild(newConfirmBtn, confirmBtn);
        cancelBtn.parentNode.replaceChild(newCancelBtn, cancelBtn);
        
        modal.classList.add('active');
        input.value = '';
        input.focus();
        
        // Atualiza o título do modal
        modal.querySelector('h2').textContent = parentId ? 'Criar Subcard' : 'Criar Card';

        // Adiciona novos handlers
        newConfirmBtn.addEventListener('click', async () => {
            const nome = input.value.trim();
            if (!nome) return;

            try {
                const formData = new FormData();
                formData.append('action', 'create_card');
                formData.append('nome', nome);
                formData.append('lista_id', listId);
                if (parentId) formData.append('parent_id', parentId);

                const response = await fetch('index.php', {
                    method: 'POST',
                    body: formData
                });

                const data = await response.json();
                if (data.success) {
                    closeCardModal();
                    await loadWorkflowLists(selectedWorkflowId);
                    initializeCardButtons();
                    initializeCardMenus();  // Adicione esta linha
                    initializeSubcardButtons();
                    initializeCardCheckboxes();
                    initializeGlobalClickHandler();
                } else {
                    throw new Error(data.message || 'Erro ao criar card');
                }
            } catch (error) {
                alert(error.message);
            }
        });

        newCancelBtn.addEventListener('click', closeCardModal);
    }

    function closeCardModal() {
        const modal = document.getElementById('createCardModal');
        modal.classList.remove('active');
        modal.querySelector('#cardName').value = '';
    }

    // ========= FUNÇÕES DE LISTA =========
    function createListElement(list) {
        const listElement = document.createElement('div');
        listElement.className = 'list-card';
        listElement.dataset.listId = list.id;
        
        const headerHtml = `
            <div class="list-header">
                <h3>${list.nome}</h3>
                <div class="list-menu-container">
                    <button class="list-menu-trigger"></button>
                    <div class="list-menu-dropdown">
                        <div class="list-menu-option" data-action="edit">Editar</div>
                        <div class="list-menu-option" data-action="delete">Apagar</div>
                    </div>
                </div>
            </div>
        `;

        listElement.innerHTML = headerHtml + `
            <div class="list-content">
                ${list.cards ? list.cards.map(card => {
                    const activeSubcards = card.subcards.filter(subcard => subcard.concluida != 1).length;
                    
                    return `
                        <div class="card ${card.concluida == 1 ? 'concluido' : ''}" 
                             data-card-id="${card.id}"
                             data-card-type="main">
                            <div class="card-wrapper">
                                <div class="card-checkbox ${card.concluida == 1 ? 'checked' : ''}" data-card-id="${card.id}"></div>
                                <div class="card-content">
                                    <div class="card-main-info">
                                        <div class="card-name">
                                            ${card.nome}
                                            <span class="subcard-count">${activeSubcards}</span>
                                        </div>
                                        ${card.subcards.length > 0 ? 
                                            `<div class="card-expand-button" role="button" aria-label="Expandir/Retrair">▶</div>` 
                                            : ''}
                                        <div class="card-menu-container">
                                            <button class="card-menu-trigger">⋮</button>
                                            <div class="card-menu">
                                                <div class="card-menu-item" data-action="edit">Editar</div>
                                                <div class="card-menu-item" data-action="delete">Apagar</div>
                                                <div class="card-menu-item" data-action="add-subcard">Adicionar Subcard</div>
                                            </div>
                                        </div>
                                    </div>
                                    ${card.timer_end ? `
                                        <div class="card-time-info">
                                            ${card.timer_end ? `
                                                <div class="card-timer ${isExpired(card.timer_end) ? 'expired' : ''}">
                                                    <i class="fas fa-clock"></i>
                                                    <span class="timer-remaining ${isExpired(card.timer_end) ? 'expired' : ''}" data-timer-end="${card.timer_end}">
                                                        ${isExpired(card.timer_end) ? 'Expirado' : 'Carregando...'}
                                                    </span>
                                                </div>
                                            ` : ''}
                                            ${card.date_end ? `
                                                <div class="card-date">
                                                    <i class="fas fa-calendar"></i>
                                                    <span class="date-end" data-date-end="${card.date_end}">
                                                        ${formatDate(card.date_end)}
                                                    </span>
                                                </div>
                                            ` : ''}
                                        </div>
                                    ` : ''}
                                </div>
                            </div>
                            ${card.subcards.length > 0 ? `
                                <div class="subcards-container" style="display: none;">
                                    ${card.subcards.map(subcard => `
                                        <div class="card subcard ${subcard.concluida == 1 ? 'concluido' : ''}" 
                                             data-card-id="${subcard.id}"
                                             data-card-type="sub">
                                            <div class="card-wrapper">
                                                <div class="card-checkbox ${subcard.concluida == 1 ? 'checked' : ''}" data-card-id="${subcard.id}"></div>
                                                <div class="card-content">
                                                    <div class="card-main-info">
                                                        <div class="card-name">${subcard.nome}</div>
                                                        <div class="card-menu-container">
                                                            <button class="card-menu-trigger">⋮</button>
                                                            <div class="card-menu">
                                                                <div class="card-menu-item" data-action="edit">Editar</div>
                                                                <div class="card-menu-item" data-action="delete">Apagar</div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    ${subcard.timer_end ? `
                                                        <div class="card-time-info">
                                                            ${subcard.timer_end ? `
                                                                <div class="card-timer ${isExpired(subcard.timer_end) ? 'expired' : ''}">
                                                                    <i class="fas fa-clock"></i>
                                                                    <span class="timer-remaining ${isExpired(subcard.timer_end) ? 'expired' : ''}" data-timer-end="${subcard.timer_end}">
                                                                        ${isExpired(subcard.timer_end) ? 'Expirado' : 'Carregando...'}
                                                                    </span>
                                                                </div>
                                                            ` : ''}
                                                            ${subcard.date_end ? `
                                                                <div class="card-date">
                                                                    <i class="fas fa-calendar"></i>
                                                                    <span class="date-end" data-date-end="${subcard.date_end}">
                                                                        ${formatDate(subcard.date_end)}
                                                                    </span>
                                                                </div>
                                                            ` : ''}
                                                        </div>
                                                    ` : ''}
                                                </div>
                                            </div>
                                        </div>
                              `).join('')}
                            </div>
                        ` : ''}
                    </div>
                `;
            }).join('') : ''}
        </div>
        <div class="list-footer">
            <button class="add-card-btn" type="button">+ Adicionar Card</button>
        </div>
    `;
        
        return listElement;
    }

    // Objeto para armazenar o estado de expansão dos cards
    let cardExpandStates = {};

    function initExpandButtons() {
        document.querySelectorAll('.card-expand-button').forEach(button => {
            const card = button.closest('.card');
            const cardId = card.dataset.cardId;
            const subcardsContainer = card.querySelector('.subcards-container');
            
            // Remove qualquer evento anterior
            button.replaceWith(button.cloneNode(true));
            const newButton = card.querySelector('.card-expand-button');
            
            // Restaura o estado anterior se existir
            if (cardExpandStates[cardId]) {
                subcardsContainer.style.display = 'block';
                newButton.innerHTML = '▼';
            } else {
                subcardsContainer.style.display = 'none';
                newButton.innerHTML = '▶';
            }

            newButton.addEventListener('click', function() {
                const isExpanded = subcardsContainer.style.display !== 'none';
                subcardsContainer.style.display = isExpanded ? 'none' : 'block';
                newButton.innerHTML = isExpanded ? '▶' : '▼';
                cardExpandStates[cardId] = !isExpanded;
            });
        });
    }

    // Modifica a função que lida com o movimento dos subcards
    function initSubcardSortable() {
        // Primeiro, inicializa o Sortable nos containers existentes
        document.querySelectorAll('.subcards-container').forEach(container => {
            initializeSortableContainer(container);
        });

        // Adiciona evento para permitir drop diretamente nos cards
        document.querySelectorAll('.card:not(.subcard)').forEach(card => {
            card.addEventListener('dragover', function(e) {
                e.preventDefault();
                this.classList.add('drop-target');
            });

            card.addEventListener('dragleave', function(e) {
                this.classList.remove('drop-target');
            });

            card.addEventListener('drop', function(e) {
                e.preventDefault();
                this.classList.remove('drop-target');

                const draggedItem = document.querySelector('.subcard.dragging');
                if (!draggedItem) return;

                handleSubcardDrop(this, draggedItem);

                // Atualiza no servidor
                const cardId = draggedItem.dataset.cardId;
                const targetCardId = this.dataset.cardId;
                const listId = this.closest('.list-card').dataset.listId;

                const formData = new FormData();
                formData.append('action', 'move_subcard');
                formData.append('subcard_id', cardId);
                formData.append('parent_card_id', targetCardId);
                formData.append('lista_id', listId);
                formData.append('posicao', 0);

                fetch('index.php', {
                    method: 'POST',
                    body: formData
                })
                .then(response => response.json())
                .then(data => {
                    if (!data.success) {
                        throw new Error(data.message || 'Erro ao mover subcard');
                    }
                    // Salva os estados atuais antes do reload
                    const currentStates = {...cardExpandStates};
                    loadWorkflowLists(selectedWorkflowId).then(() => {
                        // Restaura os estados após o reload
                        cardExpandStates = currentStates;
                        initExpandButtons();
                    });
                })
                .catch(error => {
                    loadWorkflowLists(selectedWorkflowId);
                });
            });
        });
    }

    // Função auxiliar para inicializar Sortable em um container
    function initializeSortableContainer(container) {
        new Sortable(container, {
            group: 'subcards',
            animation: 150,
            draggable: '.subcard',
            ghostClass: 'card-ghost',
            onEnd: function(evt) {
                const container = evt.to;
                const subcards = Array.from(container.querySelectorAll('.subcard'));
                const targetCard = container.closest('.card');
                const listId = targetCard.closest('.list-card').dataset.listId;
                
                // Limpa e formata os dados corretamente
                const orderData = subcards.map((card, index) => ({
                    id: card.dataset.cardId,
                    ordem: index,
                    parent_id: targetCard.dataset.cardId,
                    lista_id: listId
                }));

                // Debug
                console.log('Dados sendo enviados:', orderData);

                const formData = new FormData();
                formData.append('action', 'update_subcard_order');
                formData.append('subcards_order', JSON.stringify(orderData));

                fetch('index.php', {
                    method: 'POST',
                    body: formData
                })
                .then(response => response.text().then(text => {
                    // Debug
                    console.log('Resposta bruta do servidor:', text);
                    try {
                        return JSON.parse(text);
                    } catch (e) {
                        console.error('Erro ao parsear JSON:', e);
                        console.log('Texto que causou erro:', text);
                        throw e;
                    }
                }))
                .then(data => {
                    if (!data.success) {
                        throw new Error(data.message || 'Erro ao atualizar ordem');
                    }
                    console.log('Ordem atualizada com sucesso');
                })
                .catch(error => {
                    console.error('Erro na atualização:', error);
                });
            }
        });
    }

    // ========= FUNÇÕES DE WORKFLOW =========
    function selectWorkflow(workflowItem) {
        workflowItems.forEach(item => item.classList.remove('active'));
        workflowItem.classList.add('active');
        selectedWorkflowId = workflowItem.dataset.id;
        // Salva o ID do workflow selecionado no localStorage
        localStorage.setItem('selectedWorkflowId', selectedWorkflowId);
        workflowTitle.textContent = workflowItem.querySelector('.workflow-name').textContent;
        loadWorkflowLists(selectedWorkflowId);
    }

    // ========= EVENTOS =========
    // Eventos de Workflow
    workflowItems.forEach(item => {
        item.addEventListener('click', () => selectWorkflow(item));
    });

    // Eventos do Modal de Lista
    listModal.querySelector('.cancel-btn').addEventListener('click', closeListModal);
    listModal.querySelector('.confirm-btn').addEventListener('click', () => {
        const nome = listNameInput.value.trim();
        if (!nome) {
            alert('Por favor, digite um nome para a lista');
            return;
        }
        // ... código de criar lista ...
    });

    // Eventos do Modal de Card
    cardModal.querySelector('.cancel-btn').addEventListener('click', closeCardModal);
    cardModal.querySelector('.confirm-btn').addEventListener('click', () => {
        const nome = cardNameInput.value.trim();
        if (!nome) {
            alert('Por favor, digite um nome para o card');
            return;
        }

        // Chama a função createCard
        createCard(nome, selectedListId)
            .then(() => {
                closeCardModal();
            })
            .catch(error => {
                alert(error.message);
            });
    });

    // Fechar modais ao clicar fora
    [listModal, cardModal].forEach(modal => {
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                modal === listModal ? closeListModal() : closeCardModal();
            }
        });
    });

    // Inicialização
    if (workflowItems.length > 0) {
        // Tenta recuperar o workflow salvo
        const savedWorkflowId = localStorage.getItem('selectedWorkflowId');
        
        if (savedWorkflowId) {
            // Procura o workflow salvo
            const savedWorkflow = document.querySelector(`.workflow-item[data-id="${savedWorkflowId}"]`);
            if (savedWorkflow) {
                // Se encontrar, seleciona ele
                selectWorkflow(savedWorkflow);
            } else {
                // Se não encontrar o workflow salvo, seleciona o primeiro
                selectWorkflow(workflowItems[0]);
            }
        } else {
            // Se não tiver workflow salvo, seleciona o primeiro
            selectWorkflow(workflowItems[0]);
        }
    }

    // Atualizar a função createCard
    function createCard(nome, listaId, parentId = null) {
        if (!listaId) {
            console.warn('Tentativa de criar card sem listaId');
            return Promise.reject(new Error('Lista não selecionada'));
        }

        const formData = new FormData();
        formData.append('action', 'create_card');
        formData.append('nome', nome);
        formData.append('lista_id', listaId);
        if (parentId) {
            formData.append('parent_id', parentId);
        }

        return fetch('index.php', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (!data.success) {
                throw new Error(data.message || 'Erro ao criar card');
            }
            return data;
        });
    }

    // Atualizar a função toggleCardStatus
    function toggleCardStatus(cardId, cardElement, isSubcard = false) {
        const formData = new FormData();
        formData.append('action', 'toggle_card_status');
        formData.append('card_id', cardId);

        fetch('index.php', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                cardElement.classList.toggle('concluido');
                cardElement.querySelector('.card-checkbox').classList.toggle('checked');
                
                // Se não for subcard, não afeta os subcards
                if (!isSubcard) {
                    const subcards = cardElement.querySelectorAll('.subcard');
                    subcards.forEach(subcard => {
                        subcard.classList.toggle('concluido');
                        subcard.querySelector('.card-checkbox').classList.toggle('checked');
                    });
                }
            } else {
                throw new Error(data.message || 'Erro ao alterar status do card');
            }
        })
        .catch(error => {
            alert(error.message);
        });
    }

    
    function createCardElement(cardData, isSubcard = false) {
        const card = document.createElement('div');
        card.className = isSubcard ? 'card subcard' : 'card';
        card.dataset.cardId = cardData.id;
        
        // Wrapper para o conteúdo do card
        const cardWrapper = document.createElement('div');
        cardWrapper.className = 'card-wrapper';
    
        // Checkbox
        const checkbox = document.createElement('div');
        checkbox.className = 'card-checkbox';
        if (cardData.concluido) {
            checkbox.classList.add('checked');
            card.classList.add('concluido');
        }
        cardWrapper.appendChild(checkbox);
    
        // Conteúdo do card
        const cardContent = document.createElement('div');
        cardContent.className = 'card-content';
    
        // Nome do card
        const cardName = document.createElement('div');
        cardName.className = 'card-name';
        cardName.textContent = cardData.nome;
        cardContent.appendChild(cardName);
    
        // Informações de tempo (timer e data)
        const timeInfo = document.createElement('div');
        timeInfo.className = 'card-time-info';
    
        // Adiciona timer se existir
        if (cardData.timer_end) {
            const timerDiv = document.createElement('div');
            timerDiv.className = 'card-timer';
            timerDiv.innerHTML = `
                <i class="fas fa-clock"></i>
                <span class="timer-remaining" data-timer-end="${cardData.timer_end}">
                    Carregando...
                </span>
            `;
            timeInfo.appendChild(timerDiv);
        }
    
        // Adiciona data se existir
        if (cardData.date_end) {
            const dateDiv = document.createElement('div');
            dateDiv.className = 'card-date';
            dateDiv.innerHTML = `
                <i class="fas fa-calendar"></i>
                <span class="date-end" data-date-end="${cardData.date_end}">
                    ${formatDate(cardData.date_end)}
                </span>
            `;
            timeInfo.appendChild(dateDiv);
        }
    
        // Adiciona as informações de tempo ao conteúdo
        cardContent.appendChild(timeInfo);
        cardWrapper.appendChild(cardContent);
        card.appendChild(cardWrapper);
    
        // Se não for subcard, adiciona botão de expandir e container de subcards
        if (!isSubcard) {
            const expandButton = document.createElement('button');
            expandButton.className = 'card-expand-button';
            expandButton.innerHTML = '▶';
            cardWrapper.appendChild(expandButton);
    
            const subcardsContainer = document.createElement('div');
            subcardsContainer.className = 'subcards-container';
            subcardsContainer.style.display = 'none';
    
            if (cardData.subcards && cardData.subcards.length > 0) {
                cardData.subcards.forEach(subcard => {
                    const subcardElement = createCardElement(subcard, true);
                    subcardsContainer.appendChild(subcardElement);
                });
            }
    
            card.appendChild(subcardsContainer);
        }
    
        return card;
    }

    // Função para fechar todos os menus
    function closeAllMenus() {
        document.querySelectorAll('.card-menu.show').forEach(menu => {
            menu.classList.remove('show');
        });
    }

    // Fechar menus ao clicar fora
    document.addEventListener('click', () => {
        closeAllMenus();
    });

    // Função para carregar subcards
    function loadSubcards(parentId, container) {
        fetch(`index.php?action=get_subcards&parent_id=${parentId}`)
            .then(response => response.json())
            .then(data => {
                if (data.success && data.cards) {
                    data.cards.forEach(card => {
                        const subcardElement = createCardElement(card);
                        container.appendChild(subcardElement);
                    });
                }
            })
            .catch(error => console.error('Erro ao carregar subcards:', error));
    }



    // Atualizar a função handleCardAction
    function handleCardAction(action, cardId, cardElement) {
        // Encontra o elemento da lista pai de forma mais robusta
        const listCard = cardElement.closest('[data-list-id]');
        const listId = listCard ? listCard.dataset.listId : null;
        
        switch(action) {
            case 'edit':
                openEditCardModal(cardId);
                break;
            
            case 'add-subcard':
                // Buscar o listId do card pai via API
                fetch(`index.php?action=get_card_list&card_id=${cardId}`)
                    .then(response => response.json())
                    .then(data => {
                        if (data.success && data.lista_id) {
                            openCardModal(data.lista_id, cardId);
                        } else {
                            throw new Error(data.message || 'Erro ao obter lista do card');
                        }
                    })
                    .catch(error => {
                        alert(error.message);
                    });
                break;
            
            case 'delete':
                if (confirm('Tem certeza que deseja excluir este card?')) {
                    deleteCard(cardId)
                        .then(() => {
                            if (listId) {
                                reloadListCards(listId);
                            }
                        })
                        .catch(error => {
                            alert(error.message);
                        });
                }
                break;
        }
    }

    // Atualizar também a função que adiciona os eventos do menu
    function addCardEvents(cardElement) {
        const menuTrigger = cardElement.querySelector('.card-menu-trigger');
        const menu = cardElement.querySelector('.card-menu');
        
        if (menuTrigger && menu) {
            menuTrigger.onclick = (e) => {
                e.stopPropagation();
                closeAllMenus();
                menu.classList.toggle('show');
            };

            // Adiciona eventos aos itens do menu
            menu.querySelectorAll('.card-menu-item').forEach(item => {
                item.onclick = (e) => {
                    e.stopPropagation();
                    const action = item.dataset.action;
                    const cardId = cardElement.dataset.cardId;
                    
                    // Fecha o menu antes de executar a ação
                    menu.classList.remove('show');
                    
                    // Executa a ação
                    handleCardAction(action, cardId, cardElement);
                };
            });
        }
    }

    // Função auxiliar para atualizar contador de subcards
    function updateSubcardCount(parentCard) {
        const countElement = parentCard.querySelector('.subcard-count');
        if (countElement) {
            const currentCount = parseInt(countElement.textContent.match(/\d+/)[0] || '0');
            countElement.textContent = `(${currentCount + 1})`;
        }
    }

    // Adicionar função para recarregar os cards de uma lista
    async function reloadListCards(listId) {
        if (!listId) {
            console.error('ListId não fornecido para reloadListCards');
            return;
        }

        try {
            const response = await fetch(`index.php?action=get_list_cards&list_id=${listId}`);
            const data = await response.json();
            
            if (data.success) {
                const listElement = document.querySelector(`[data-list-id="${listId}"]`);
                if (listElement) {
                    // Atualiza os cards
                    const cardsContainer = listElement.querySelector('.list-content');
                    cardsContainer.innerHTML = data.cards.map(card => {
                        // Verifica se é um card principal (sem parent_id)
                        if (!card.parent_id) {
                            return `
                                <div class="card ${card.concluida == 1 ? 'concluido' : ''} ${card.subcards && card.subcards.length > 0 ? 'card-with-subcards' : ''}" 
                                     data-card-id="${card.id}">
                                    ${card.subcards && card.subcards.length > 0 ? '<div class="card-expand-button">▶</div>' : ''}
                                    <div class="card-wrapper">
                                        <div class="card-checkbox ${card.concluida == 1 ? 'checked' : ''}"></div>
                                        <div class="card-content">
                                            ${card.nome}
                                            ${card.timer_active === '1' && card.timer_end ? `
                                                <div class="card-timer ${isExpired(card.timer_end) ? 'expired' : ''}">
                                                    <i class="fas fa-clock"></i>
                                                    <span class="timer-remaining ${isExpired(card.timer_end) ? 'expired' : ''}" data-timer-end="${card.timer_end}">
                                                        ${isExpired(card.timer_end) ? 'Expirado' : 'Carregando...'}
                                                    </span>
                                                </div>
                                            ` : ''}
                                            ${card.date_active === '1' && card.date_end ? `
                                                <div class="card-date">
                                                    <i class="fas fa-calendar"></i>
                                                    <span class="date-end ${isDateExpired(card.date_end) ? 'expired' : ''}">
                                                        ${formatDate(card.date_end)}
                                                    </span>
                                                </div>
                                            ` : ''}
                                            ${card.subcards && card.subcards.length > 0 ? 
                                              `<span class="subcard-count">(${card.subcards.length})</span>` : ''}
                                        </div>
                                        <div class="card-menu-container">
                                            <button class="card-menu-trigger">⋮</button>
                                            <div class="card-menu">
                                                <div class="card-menu-item" data-action="edit">Editar</div>
                                                <div class="card-menu-item" data-action="subcard">Criar Subcard</div>
                                                <div class="card-menu-item" data-action="delete">Apagar</div>
                                            </div>
                                        </div>
                                    </div>
                                    ${card.subcards && card.subcards.length > 0 ? `
                                        <div class="subcards-container">
                                            ${card.subcards.map(subcard => `
                                                <div class="card subcard ${subcard.concluida == 1 ? 'concluido' : ''}" 
                                                     data-card-id="${subcard.id}">
                                                    <div class="card-wrapper">
                                                        <div class="card-checkbox ${subcard.concluida == 1 ? 'checked' : ''}"></div>
                                                        <div class="card-content">${subcard.nome}</div>
                                                        <div class="card-menu-container">
                                                            <button class="card-menu-trigger">⋮</button>
                                                            <div class="card-menu">
                                                                <div class="card-menu-item" data-action="edit">Editar</div>
                                                                <div class="card-menu-item" data-action="delete">Apagar</div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                            `).join('')}
                                        </div>
                                    ` : ''}
                                </div>
                            `;
                        }
                        return ''; // Retorna vazio para cards que são subcards
                    }).join('');

                    // Reaplica os event listeners em todos os cards
                    listElement.querySelectorAll('.card').forEach(cardElement => {
                        const menuTrigger = cardElement.querySelector('.card-menu-trigger');
                        const menu = cardElement.querySelector('.card-menu');
                        const checkbox = cardElement.querySelector('.card-checkbox');
                        const expandButton = cardElement.querySelector('.card-expand-button');

                        // Event listener para o menu
                        if (menu) {
                            menu.querySelectorAll('.card-menu-item').forEach(item => {
                                item.addEventListener('click', (e) => {
                                    e.stopPropagation();
                                    const action = item.dataset.action;
                                    if (action === 'subcard') {
                                        const cardId = cardElement.dataset.cardId;
                                        fetch(`index.php?action=get_card_list&card_id=${cardId}`)
                                            .then(response => response.json())
                                            .then(data => {
                                                if (data.success && data.lista_id) {
                                                    openCardModal(data.lista_id, cardId);
                                                } else {
                                                    throw new Error(data.message || 'Erro ao obter lista do card');
                                                }
                                            })
                                            .catch(error => {
                                                alert(error.message);
                                            });
                                    } else {
                                        handleCardAction(action, cardElement.dataset.cardId, cardElement);
                                    }
                                    menu.classList.remove('show');
                                });
                            });
                        }

                        // Event listener para o menu trigger
                        if (menuTrigger) {
                            menuTrigger.addEventListener('click', (e) => {
                                e.stopPropagation();
                                closeAllMenus();
                                menu.classList.toggle('show');
                            });
                        }

                        // Event listener para o checkbox
                        if (checkbox) {
                            checkbox.addEventListener('click', (e) => {
                                e.stopPropagation();
                                toggleCardStatus(cardElement.dataset.cardId, cardElement);
                            });
                        }

                        // Event listener para o botão de expandir
                        if (expandButton) {
                            expandButton.addEventListener('click', (e) => {
                                e.stopPropagation();
                                expandButton.classList.toggle('expanded');
                                const subcardsContainer = cardElement.querySelector('.subcards-container');
                                if (subcardsContainer) {
                                    subcardsContainer.classList.toggle('show');
                                }
                            });
                        }
                    });
                }
            }
        } catch (error) {
            console.error('Erro ao recarregar cards:', error);
        }
    }

    // Atualizar a função initListSortable
    function initListSortable() {
        const listsContainer = document.querySelector('.lists-container');
        if (!listsContainer) return;

        Sortable.create(listsContainer, {
            animation: 150,
            draggable: '.list-card',
            handle: '.list-header',
            filter: '.add-list',
            preventOnFilter: true,
            onEnd: function(evt) {
                const lists = Array.from(listsContainer.querySelectorAll('.list-card')).map((list, index) => ({
                    id: list.dataset.listId,
                    ordem: index
                }));

                const formData = new FormData();
                formData.append('action', 'update_lists_order');
                formData.append('lists_order', JSON.stringify(lists));

                fetch('index.php', {
                    method: 'POST',
                    body: formData
                })
                .then(response => response.json())
                .then(data => {
                    if (!data.success) {
                        throw new Error(data.message || 'Erro ao atualizar ordem das listas');
                    }
                })
                .catch(error => {
                    loadWorkflowLists(selectedWorkflowId);
                });
            }
        });
    }

    // Função para criar container de subcards apenas quando necessário
    function createSubcardsContainer(card) {
        const container = document.createElement('div');
        container.className = 'subcards-container';
        card.appendChild(container);
        initSubcardSortable(container);
        return container;
    }

    // Handler para quando um subcard é arrastado sobre um card
    function handleSubcardDragOver(card) {
        if (!card.querySelector('.subcards-container')) {
            createSubcardsContainer(card);
        }
        card.classList.add('card-dragover');
    }

    // Função para atualizar a ordem das listas no banco
    function updateListsOrder(newOrder) {
        const formData = new FormData();
        formData.append('action', 'update_lists_order');
        formData.append('lists_order', JSON.stringify(newOrder));

        fetch('index.php', {
            method: 'POST',
            body: formData
        })
        .then(response => response.text())  // Primeiro pegamos o texto puro
        .then(text => {
            try {
                return JSON.parse(text);
            } catch (e) {
                console.error('Erro ao parsear JSON:', e);
                console.error('Texto recebido:', text);
                throw new Error('Resposta inválida do servidor');
            }
        })
        .then(data => {
            if (!data.success) {
                throw new Error(data.message || 'Erro ao atualizar ordem das listas');
            }
        })
        .catch(error => {
            alert('Erro ao atualizar ordem das listas: ' + error.message);
        });
    }

    // Adicione esta função após initListSortable
    function initCardSortable() {
        const lists = document.querySelectorAll('.list-content');

        lists.forEach((list, index) => {
            Sortable.create(list, {
                group: 'cards',
                animation: 100,
                draggable: '.card:not(.subcard)',  // Cards principais apenas
                handle: '.card-wrapper',  // Mudamos para card-wrapper que é a área clicável
                filter: '.subcards-container, .card-menu-container, .card-checkbox, .card-expand-button',
                preventOnFilter: true,
                ghostClass: 'sortable-ghost',
                chosenClass: 'sortable-chosen',
                dragClass: 'sortable-drag',
                
                onStart: function(evt) {
                    const lists = document.querySelectorAll('.list-content');
                    lists.forEach(list => list.classList.add('can-receive-card'));
                    evt.item.classList.add('is-dragging');
                },
                
                onEnd: function(evt) {
                    const lists = document.querySelectorAll('.list-content');
                    lists.forEach(list => list.classList.remove('can-receive-card'));
                    evt.item.classList.remove('is-dragging');

                    if (evt.from !== evt.to) {
                        const cardId = evt.item.dataset.cardId;
                        const newListId = evt.to.closest('.list-card').dataset.listId;
                        const newIndex = Array.from(evt.to.children).indexOf(evt.item);
                        
                        updateCardPosition({
                            cardId: cardId,
                            newListId: newListId,
                            newIndex: newIndex
                        });
                    }
                }
            });
        });
    }

    // Funço para atualizar posição de subcards
    function updateSubcardPosition(data) {
        const formData = new FormData();
        formData.append('action', 'update_subcard_position');
        formData.append('card_id', data.cardId);
        formData.append('parent_id', data.parentId);
        formData.append('lista_id', data.listId);
        formData.append('posicao', data.position);

        fetch('index.php', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (!data.success) {
                throw new Error(data.message || 'Erro ao atualizar posição do subcard');
            }
            // Após sucesso, recarrega os cards da lista para atualizar contadores
            reloadListCards(data.listId);
        })
        .catch(error => {
            alert('Erro ao atualizar posição do subcard: ' + error.message);
            window.location.reload(); // Recarrega em caso de erro
        });
    }

    // Função para atualizar a posição do card
    function updateCardPosition(data) {
        const formData = new FormData();
        formData.append('action', 'update_card_position');
        formData.append('card_id', data.cardId);
        formData.append('lista_id', data.newListId);
        formData.append('ordem', data.newIndex);
        formData.append('data_atualizacao', new Date().toISOString().slice(0, 19).replace('T', ' '));

        fetch('index.php', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (!data.success) {
                throw new Error(data.message || 'Erro ao atualizar posição do card');
            }
            console.log('Card e subcards atualizados com sucesso');
        })
        .catch(error => {
            alert('Erro ao atualizar posição do card: ' + error.message);
            loadWorkflowLists(selectedWorkflowId);
        });
    }

    function isMainCard(element) {
        return element.getAttribute('data-card-type') === 'main';
    }

    function isSubcard(element) {
        return element.getAttribute('data-card-type') === 'sub';
    }

    // Adicione este listener para garantir que a função só é chamada após o DOM estar pronto
    document.addEventListener('DOMContentLoaded', function() {
        initCardSortable();
    });

    // Adicione esta função no seu script.js
    function setupCardObserver() {
        // Observador para mudanças no DOM
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                if (mutation.addedNodes.length) {
                    initExpandButtons();
                }
            });
        });

        // Observa a lista-container para mudanças
        const listsContainer = document.querySelector('.lists-container');
        if (listsContainer) {
            observer.observe(listsContainer, { 
                childList: true, 
                subtree: true 
            });
        }
    }

    // Modifica a função loadWorkflowLists para retornar uma Promise
    async function loadWorkflowLists(workflowId) {
        try {
            const response = await fetch(`index.php?action=get_workflow_lists&workflow_id=${workflowId}`);
            if (!response.ok) {
                throw new Error('Erro na resposta do servidor');
            }
            const data = await response.json();
            
            if (!data.success) {
                throw new Error(data.message || 'Erro ao carregar listas');
            }

            // Atualiza o título do workflow
            const workflowName = document.querySelector(`.workflow-item[data-id="${workflowId}"]`)?.querySelector('.workflow-name')?.textContent;
            if (workflowName) {
                document.querySelector('.selected-workflow-name').textContent = workflowName;
            }

            // Renderiza as listas
            const listsContainer = document.querySelector('.lists-container');
            if (!listsContainer) return;

            // Mantém o botão de adicionar lista
            const addListButton = listsContainer.querySelector('.add-list');
            
            // Limpa o container mantendo o botão de adicionar
            listsContainer.innerHTML = '';
            
            // Renderiza cada lista
            data.lists.forEach(list => {
                const listElement = createListElement(list);
                listsContainer.appendChild(listElement);
            });

            // Adiciona o botão de adicionar lista de volta
            if (addListButton) {
                listsContainer.appendChild(addListButton);
            }

            // Inicializa todas as funcionalidades
            initializeListButtons();
            initializeCardButtons();
            initializeSubcardButtons();  // Adicione esta linha
            initCardSortable();
            initSubcardSortable();
            initExpandButtons();
            initListSortable();
            initializeCardMenus();
            initializeCardCheckboxes();
            initializeListMenus();
            initializeGlobalClickHandler(); // Adiciona esta linha
            initializeAddCardButtons();

            // Após renderizar os cards, inicie a atualização dos timers
            updateCardTimers();
            // Atualiza os timers a cada segundo
            setInterval(updateCardTimers, 1000);

            return Promise.resolve(); // Retorna uma Promise resolvida
        } catch (error) {
            console.error('Erro ao carregar listas:', error);
            return Promise.reject(error);
        }
    }

    // Adicione esta função após loadWorkflowLists completar com sucesso
    function onWorkflowLoaded() {
        initExpandButtons();
    }

    // Adicione esta função ao seu script.js
    function debugCardStructure() {
        document.querySelectorAll('.card').forEach(card => {
            console.log('Card:', {
                id: card.dataset.cardId,
                hasExpandButton: !!card.querySelector('.card-expand-button'),
                hasSubcards: !!card.querySelector('.subcards-container'),
                subcardsVisible: card.querySelector('.subcards-container')?.style.display
            });
        });
    }

    // Chame após inicializar os botões
    document.addEventListener('DOMContentLoaded', function() {
        initExpandButtons();
        debugCardStructure();
    });

    function initializeCardButtons() {
        // Adiciona listeners para os menus dos cards
        document.querySelectorAll('.card-menu-trigger').forEach(trigger => {
            trigger.addEventListener('click', (e) => {
                e.stopPropagation();
                const menu = trigger.nextElementSibling;
                // Fecha outros menus abertos
                document.querySelectorAll('.card-menu.show').forEach(m => {
                    if (m !== menu) m.classList.remove('show');
                });
                menu.classList.toggle('show');
            });
        });

        // Adiciona listeners para as opções do menu
        document.querySelectorAll('.card-menu-item').forEach(item => {
            item.addEventListener('click', (e) => {
                e.stopPropagation();
                const action = item.dataset.action;
                const card = item.closest('.card');
                const cardId = card.dataset.cardId;
                const listId = card.closest('.list-card').dataset.listId;

                switch(action) {
                    case 'edit':
                        openEditCardModal(cardId);
                        break;
                    case 'delete':
                        if (confirm('Tem certeza que deseja apagar este card?')) {
                            deleteCard(cardId);
                        }
                        break;
                    case 'add-subcard':
                        openCardModal(listId, cardId); // Passa o cardId como parentId
                        break;
                }

                // Fecha o menu após a ação
                item.closest('.card-menu').classList.remove('show');
            });
        });

        // Fecha os menus ao clicar fora
        document.addEventListener('click', () => {
            document.querySelectorAll('.card-menu.show').forEach(menu => {
                menu.classList.remove('show');
            });
        });
    }

    // Chame esta função após carregar as listas e após qualquer atualizaão
    function reloadListCards(listId) {
        // ... código existente ...
        
        // Após atualizar o conteúdo
        initializeCardButtons();
    }

    // Também na inicialização
    document.addEventListener('DOMContentLoaded', function() {
        initializeCardButtons();
    });

    // Inicialização dos botões de lista
    function initializeListButtons() {
        const createListBtn = document.querySelector('.create-list-btn');
        
        if (createListBtn) {
            createListBtn.onclick = function(e) {
                e.preventDefault();
                openListModal(); // Chama a função original
            };
            createListBtn.disabled = false;
        }
    }

    // Chame esta função após carregar um workflow
    function onWorkflowSelected(workflowId) {
        selectedWorkflowId = workflowId;
        initializeListButtons();
    }

    // Na funão que lida com o drop do subcard
    function handleSubcardDrop(targetCard, draggedItem) {
        let subcardsContainer = targetCard.querySelector('.subcards-container');
        if (!subcardsContainer) {
            subcardsContainer = document.createElement('div');
            subcardsContainer.className = 'subcards-container';
            targetCard.appendChild(subcardsContainer);
        }

        // Move o subcard para o container
        subcardsContainer.style.display = 'block';
        subcardsContainer.appendChild(draggedItem);

        // Marca o card como expandido
        const cardId = targetCard.dataset.cardId;
        cardExpandStates[cardId] = true;
        
        // Atualiza o botão de expandir
        const expandButton = targetCard.querySelector('.card-expand-button');
        if (expandButton) {
            expandButton.innerHTML = '▼';
        }
    }

    // Adicionar após as outras funções de inicialização
    function initializeCardMenus() {
        // Remove event listeners antigos primeiro
        document.querySelectorAll('.card-menu-trigger').forEach(trigger => {
            const newTrigger = trigger.cloneNode(true);
            newTrigger.innerHTML = '⋮';
            trigger.parentNode.replaceChild(newTrigger, trigger);
        });

        document.querySelectorAll('.card-menu-option').forEach(option => {
            const newOption = option.cloneNode(true);
            option.parentNode.replaceChild(newOption, option);
        });

        // Adiciona novos event listeners
        document.querySelectorAll('.card-menu-trigger').forEach(trigger => {
            trigger.addEventListener('click', handleCardMenuTrigger);
        });

        document.querySelectorAll('.card-menu-option').forEach(option => {
            option.addEventListener('click', handleCardMenuOption);
        });
    }

    // Handler separado para o trigger do menu
    function handleCardMenuTrigger(event) {
        event.stopPropagation();
        const card = this.closest('.card');
        const cardId = card.dataset.cardId;
        
        console.log('Click no menu do card:', cardId);
        console.log('- Evento:', event);
        console.log('- Target:', event.target);

        const menu = this.nextElementSibling;
        
        // Fecha todos os outros menus primeiro
        document.querySelectorAll('.card-menu').forEach(m => {
            if (m !== menu) {
                m.classList.remove('show');
                m.style.display = 'none';
            }
        });
        
        // Toggle do menu atual
        const isVisible = menu.classList.contains('show');
        if (!isVisible) {
            menu.classList.add('show');
            menu.style.display = 'block';
            console.log('- Menu agora está: visível');
        } else {
            menu.classList.remove('show');
            menu.style.display = 'none';
            console.log('- Menu agora está: oculto');
        }
    }

    // Handler separado para as opções do menu
    async function handleCardMenuOption(event) {
        event.stopPropagation();
        
        // Previne múltiplos clicks
        if (this.dataset.processing === 'true') return;
        this.dataset.processing = 'true';
        
        try {
            const card = this.closest('.card');
            const cardId = card.dataset.cardId;
            const action = this.dataset.action;

            console.log('Click em opção do menu do card:', action);
            console.log('- Ação:', action);
            console.log('- Card ID:', cardId);

            if (action === 'delete') {
                await deleteCard(cardId);
            } else if (action === 'add-subcard') {
                // ... lógica para adicionar subcard ...
            }
            // ... outras ações ...

        } catch (error) {
            console.error('Erro ao executar ação:', error);
            alert(error.message);
        } finally {
            // Remove flag de processamento
            this.dataset.processing = 'false';
            
            // Fecha o menu após a ação
            const menu = this.closest('.card-menu');
            if (menu) {
                menu.classList.remove('show');
                menu.style.display = 'none';
            }
        }
    }

    // Função de deletar card atualizada
    async function deleteCard(cardId) {
        console.log('Enviando requisição para deletar card:', cardId);
        
        // Previne múltiplas chamadas
        if (deleteCard.isProcessing) {
            console.log('Já existe uma requisição de delete em andamento');
            return;
        }
        
        deleteCard.isProcessing = true;

        const formData = new FormData();
        formData.append('action', 'delete_card');
        formData.append('card_id', cardId);

        fetch('index.php', {
            method: 'POST',
            body: formData
        })
        .then(response => response.text()) // Primeiro pegamos o texto
        .then(text => {
            try {
                // Pega apenas o primeiro JSON válido da resposta
                const jsonMatch = text.match(/\{.*?\}/);
                if (!jsonMatch) {
                    throw new Error('Resposta inválida do servidor');
                }
                return JSON.parse(jsonMatch[0]);
            } catch (e) {
                console.error('Erro ao parsear JSON:', e);
                console.error('Texto recebido:', text);
                throw new Error('Resposta inválida do servidor');
            }
        })
        .then(data => {
            if (data.success) {
                console.log('Card deletado com sucesso');
                return loadWorkflowLists(selectedWorkflowId);
            } else {
                throw new Error(data.message || 'Erro ao deletar card');
            }
        })
        .catch(error => {
            console.error('Erro ao deletar card:', error);
            alert('Erro ao deletar card: ' + error.message);
        })
        .finally(() => {
            deleteCard.isProcessing = false;
        });
    }

    // Adicionar após as outras funções
    function initializeCardCheckboxes() {
        document.querySelectorAll('.card-checkbox').forEach(checkbox => {
            checkbox.addEventListener('click', function(e) {
                e.stopPropagation();
                const cardId = this.dataset.cardId;
                const isChecked = this.classList.contains('checked');
                
                toggleCardComplete(cardId, !isChecked);
            });
        });
    }

    function toggleCardComplete(cardId, complete) {
        const formData = new FormData();
        formData.append('action', 'toggle_card_complete');
        formData.append('card_id', cardId);
        formData.append('complete', complete ? 1 : 0);

        fetch('index.php', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                const card = document.querySelector(`.card[data-card-id="${cardId}"]`);
                const checkbox = card.querySelector('.card-checkbox');
                
                if (complete) {
                    card.classList.add('concluido');
                    checkbox.classList.add('checked');
                } else {
                    card.classList.remove('concluido');
                    checkbox.classList.remove('checked');
                }
            } else {
                throw new Error(data.message || 'Erro ao atualizar status do card');
            }
        })
        .catch(error => {
            alert('Erro ao atualizar status do card: ' + error.message);
            loadWorkflowLists(selectedWorkflowId);
        });
    }

    // Adicione esta função no início do arquivo, junto com as outras funções
    function openEditCardModal(cardId) {
        const modal = document.getElementById('editCardModal');
        const nameInput = modal.querySelector('#editCardName');
        const descriptionInput = modal.querySelector('#editCardDescription');
        const confirmBtn = modal.querySelector('.confirm-btn');
        const cancelBtn = modal.querySelector('.cancel-btn');
        
        // Guarda referência ao card atual
        const cardElement = document.querySelector(`.card[data-card-id="${cardId}"]`);
        if (!cardElement) {
            console.error('Card não encontrado');
            return;
        }

        // Remove handlers antigos
        const newConfirmBtn = confirmBtn.cloneNode(true);
        const newCancelBtn = cancelBtn.cloneNode(true);
        confirmBtn.parentNode.replaceChild(newConfirmBtn, confirmBtn);
        cancelBtn.parentNode.replaceChild(newCancelBtn, cancelBtn);

        // Busca os dados do card
        fetch(`index.php?action=get_card&card_id=${cardId}`)
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    const cardData = data.card;
                    nameInput.value = cardData.nome;
                    descriptionInput.value = cardData.descricao;
                    
                    // Inicializa os controles de tempo
                    if (timeManager) {
                        timeManager.initializeTimeControls(cardId, {
                            end: cardData.timer_end,
                            active: cardData.timer_active === '1',
                            sound: cardData.timer_sound === '1'
                        }, {
                            end: cardData.date_end,
                            active: cardData.date_active === '1',
                            sound: cardData.date_sound === '1'
                        });
                    }

                    modal.classList.add('active');

                    // Adiciona novos handlers
                    newConfirmBtn.addEventListener('click', () => {
                        const formData = new FormData();
                        formData.append('action', 'update_card');
                        formData.append('card_id', cardId);
                        formData.append('nome', nameInput.value);
                        formData.append('descricao', descriptionInput.value);

                        fetch('index.php', {
                            method: 'POST',
                            body: formData
                        })
                        .then(response => response.json())
                        .then(data => {
                            if (data.success) {
                                modal.classList.remove('active');
                                loadWorkflowLists(selectedWorkflowId);
                            } else {
                                throw new Error(data.message || 'Erro ao atualizar card');
                            }
                        })
                        .catch(error => {
                            alert(error.message);
                        });
                    });

                    newCancelBtn.addEventListener('click', () => {
                        modal.classList.remove('active');
                    });
                }
            })
            .catch(error => {
                console.error('Erro ao carregar dados do card:', error);
            });
    }

    function initializeListMenus() {
        console.log('Inicializando menus das listas...');
        
        // Remove handler global antigo
        document.removeEventListener('click', handleListMenuClick);
        
        // Remove handlers antigos primeiro
        document.querySelectorAll('.list-menu-trigger').forEach(trigger => {
            const newTrigger = trigger.cloneNode(true);
            newTrigger.innerHTML = '⋮';
            trigger.parentNode.replaceChild(newTrigger, trigger);
        });

        // Handler global único para todos os menus
        async function handleListMenuClick(e) {
            // Se clicou em uma opção do menu
            if (e.target.matches('.list-menu-option')) {
                console.log('Click em opção do menu');
                e.stopPropagation();
                
                const action = e.target.dataset.action;
                const listCard = e.target.closest('.list-card');
                const listId = listCard?.dataset.listId;
                
                console.log('- Ação:', action);
                console.log('- List ID:', listId);
                
                // Previne múltiplos clicks
                if (e.target.dataset.processing === 'true') return;
                e.target.dataset.processing = 'true';
                
                try {
                    // Executa a ação correspondente
                    if (action === 'delete') {
                        if (confirm('Tem certeza que deseja excluir esta lista?')) {
                            const formData = new FormData();
                            formData.append('action', 'delete_list');
                            formData.append('list_id', listId);

                            try {
                                const response = await fetch('index.php', {
                                    method: 'POST',
                                    body: formData
                                });

                                const text = await response.text(); // Primeiro pegamos o texto
                                console.log('Resposta bruta do servidor:', text); // Debug

                                // Pega apenas o primeiro JSON válido da resposta
                                const jsonMatch = text.match(/\{.*?\}/);
                                if (!jsonMatch) {
                                    throw new Error('Resposta inválida do servidor');
                                }

                                const data = JSON.parse(jsonMatch[0]);
                                console.log('Dados parseados:', data);

                                if (data.success) {
                                    await loadWorkflowLists(selectedWorkflowId);
                                    console.log('Lista deletada com sucesso');
                                } else {
                                    throw new Error(data.message || 'Erro ao deletar lista');
                                }
                            } catch (error) {
                                console.error('Erro completo:', error);
                                alert('Erro ao deletar lista: ' + error.message);
                            } finally {
                                // Fecha o menu após a ação, independente do resultado
                                const menu = e.target.closest('.list-menu-dropdown');
                                if (menu) {
                                    menu.classList.remove('show');
                                    menu.style.display = 'none';
                                }
                            }
                        }
                    }
                } catch (error) {
                    console.error('Erro ao executar ação:', error);
                    alert(error.message);
                } finally {
                    // Remove flag de processamento
                    e.target.dataset.processing = 'false';
                    
                    // Fecha o menu após a ação
                    const menu = e.target.closest('.list-menu-dropdown');
                    if (menu) {
                        menu.classList.remove('show');
                        menu.style.display = 'none';
                    }
                }
                return;
            }
            
            // Se clicou em um trigger
            if (e.target.matches('.list-menu-trigger')) {
                console.log('Click no trigger');
                e.stopPropagation();
                e.preventDefault();
                
                const menuContainer = e.target.closest('.list-menu-container');
                const menu = menuContainer?.querySelector('.list-menu-dropdown');
                
                console.log('Menu container:', menuContainer);
                console.log('Menu element:', menu);
                
                if (!menu) {
                    console.error('Menu não encontrado!');
                    return;
                }
                
                // Fecha outros menus primeiro
                document.querySelectorAll('.list-menu-dropdown.show').forEach(m => {
                    if (m !== menu) {
                        console.log('Fechando outro menu');
                        m.classList.remove('show');
                        m.style.display = 'none';
                    }
                });
                
                // Verifica se o menu está visível
                const isVisible = menu.classList.contains('show');
                console.log('- Menu está visível:', isVisible);
                console.log('- Classes do menu antes:', menu.className);
                
                // Toggle da visibilidade
                if (isVisible) {
                    menu.classList.remove('show');
                    menu.style.display = 'none';
                    console.log('- Menu fechado');
                } else {
                    menu.classList.add('show');
                    menu.style.display = 'block';
                    console.log('- Menu aberto');
                }
                
                console.log('- Classes do menu depois:', menu.className);
                console.log('- Display style:', menu.style.display);
            }
            // Se clicou fora de qualquer menu
            else if (!e.target.closest('.list-menu-container')) {
                document.querySelectorAll('.list-menu-dropdown.show').forEach(menu => {
                    menu.classList.remove('show');
                    menu.style.display = 'none';
                    console.log('- Fechando menu');
                });
            }
        }

        // Adiciona um único handler global
        document.addEventListener('click', handleListMenuClick);
    }

    function handleGlobalClick(e) {
        // Verifica se o evento existe
        if (!e) return;

        // Não fecha se clicou dentro de um menu
        if (e.target.closest('.list-menu-container') || e.target.closest('.card-menu-container')) {
            return;
        }

        // Fecha todos os menus abertos
        closeAllMenus();
    }

    function closeAllMenus() {
        // Fecha todos os menus abertos sem depender do evento
        document.querySelectorAll('.list-menu-dropdown.show, .card-menu.show').forEach(menu => {
            menu.classList.remove('show');
        });
    }

    // Função para tratar as ações do menu da lista
    function handleListAction(action, listId, listElement) {
        switch(action) {
            case 'editar':
                openEditListModal(listId);
                break;
            
            case 'apagar':
                if (confirm('Tem certeza que deseja excluir esta lista?')) {
                    deleteList(listId)
                        .then(() => {
                            listElement.remove();
                        })
                        .catch(error => {
                            alert(error.message);
                        });
                }
                break;
        }
    }

    async function deleteList(listId) {
        try {
            if (!confirm('Tem certeza que deseja excluir esta lista?')) {
                return false;
            }
    
            const formData = new FormData();
            formData.append('action', 'delete_list');
            formData.append('list_id', listId);
    
            const response = await fetch('index.php', {
                method: 'POST',
                body: formData
            });
    
            const data = await response.json();
            
            if (data.success) {
                await loadWorkflowLists(selectedWorkflowId);
                return true;
            } else {
                throw new Error(data.message || 'Erro ao excluir lista');
            }
        } catch (error) {
            console.error('Erro ao deletar lista:', error);
            alert(error.message);
            return false;
        }
    }

    // Adicione estas funções no script.js
    function updateCardTimer(cardId) {
        const timerMinutes = document.getElementById('timerMinutes').value;
        const timerActive = document.querySelector('.timer-start-btn').classList.contains('active');
        const timerSound = document.getElementById('timerSound').checked;
        
        const formData = new FormData();
        formData.append('action', 'update_card');
        formData.append('card_id', cardId);
        formData.append('timer_minutes', timerMinutes);
        formData.append('timer_active', timerActive);
        formData.append('timer_sound', timerSound);

        fetch('index.php', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                updateTimerDisplay(cardId);
            }
        });
    }

    function updateCardDate(cardId) {
        const dateEnd = document.getElementById('dateEnd').value;
        const dateActive = document.querySelector('.date-start-btn').classList.contains('active');
        const dateSound = document.getElementById('dateSound').checked;
        
        const formData = new FormData();
        formData.append('action', 'update_card');
        formData.append('card_id', cardId);
        formData.append('date_end', dateEnd);
        formData.append('date_active', dateActive);
        formData.append('date_sound', dateSound);

        fetch('index.php', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                updateDateDisplay(cardId);
            }
        });
    }

    function calculateTimeRemaining(endDate) {
        const now = new Date();
        const diff = endDate - now;
        
        if (diff <= 0) return 'Finalizado';
        
        const days = Math.floor(diff / (1000 * 60 * 60 * 24));
        const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
        const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
        
        return `${days}d ${hours}h ${minutes}m`;
    }

    // Sistema de Timer e Data
    class TimeManager {
        constructor() {
            this.timers = new Map();
            this.audioAlert = new Audio('notification.mp3');
        }

        initializeTimeControls(cardId, timerData, dateData) {
            
            // Inicializa Timer
            const timerBtn = document.querySelector('.timer-start-btn');
            const timerMinutes = document.getElementById('timerMinutes');
            const timerSound = document.getElementById('timerSound');
            const timerStatus = document.querySelector('.timer-status');

            if (timerData.end) {
                const timeLeft = this.calculateTimeRemaining(timerData.end);
                if (timeLeft > 0) {
                    const minutes = Math.floor(timeLeft / 60000);
                    timerMinutes.value = minutes;
                    timerStatus.textContent = this.formatTime(timeLeft);
                    
                    if (timerData.active) {
                        timerBtn.classList.add('active');
                        timerBtn.textContent = '⏸';
                        this.startTimer(cardId, timerData.end);
                    }
                } else {
                    timerStatus.textContent = 'Expirado';
                }
            }

            timerSound.checked = timerData.sound === '1';
            timerBtn.onclick = () => this.toggleTimer(cardId);
            // Inicializa Data
            const dateBtn = document.querySelector('.date-start-btn');
            const dateEnd = document.getElementById('dateEnd');
            const dateSound = document.getElementById('dateSound');
            const dateStatus = document.querySelector('.date-status');

            if (dateData.end) {
                dateEnd.value = dateData.end.split(' ').join('T');
                // Agora verifica se é true ao invés de '1'
                const isActive = dateData.active === true;
                console.log('É ativo?', isActive);
                
                dateStatus.textContent = isActive ? formatDate(dateData.end) : 'Inativo';
                
                if (isActive) {
                    dateBtn.classList.add('active');
                    dateBtn.textContent = '⏸';
                } else {
                    dateBtn.classList.remove('active');
                    dateBtn.textContent = '▶';
                }
            }

            dateSound.checked = dateData.sound === true; // Aqui também ajustamos para boolean
            
            // Adiciona eventos para a data
            dateBtn.onclick = () => this.toggleDate(cardId);
            dateEnd.onchange = () => this.updateDate(cardId);
            
        }

        calculateTimeRemaining(endTime) {
            const now = new Date();
            const end = new Date(endTime);
            return end - now;
        }

        formatTime(ms) {
            const minutes = Math.floor(ms / 60000);
            const seconds = Math.floor((ms % 60000) / 1000);
            return `${minutes}:${seconds.toString().padStart(2, '0')}`;
        }

        startTimer(cardId, endTime) {
            if (this.timers.has(cardId)) {
                clearInterval(this.timers.get(cardId));
            }

            const timer = setInterval(() => {
                const timeLeft = this.calculateTimeRemaining(endTime);
                
                const timerStatus = document.querySelector('.timer-status');
                
                if (timeLeft <= 0) {
                    clearInterval(timer);
                    timerStatus.textContent = 'Expirado';
                    if (document.getElementById('timerSound').checked) {
                        this.audioAlert.play();
                    }
                    const btn = document.querySelector('.timer-start-btn');
                    btn.classList.remove('active');
                    btn.textContent = '▶';
                } else {
                    timerStatus.textContent = this.formatTime(timeLeft);
                }
            }, 1000);

            this.timers.set(cardId, timer);
        }

        stopTimer(cardId) {
            if (this.timers.has(cardId)) {
                clearInterval(this.timers.get(cardId));
                this.timers.delete(cardId);
            }
        }

        toggleTimer(cardId) {
            const btn = document.querySelector('.timer-start-btn');
            const isActive = btn.classList.contains('active');
            const minutes = parseInt(document.getElementById('timerMinutes').value);

            if (isActive) {
                this.stopTimer(cardId);
                btn.classList.remove('active');
                btn.textContent = '▶';
                this.saveTimerState(cardId, false).then(success => {
                    if (success) {
                        loadWorkflowLists(selectedWorkflowId);
                    }
                });
            } else if (minutes > 0) {
                this.saveTimerState(cardId, true).then(success => {
                    if (success) {
                        const endTime = new Date();
                        endTime.setMinutes(endTime.getMinutes() + minutes);
                        this.startTimer(cardId, endTime);
                        btn.classList.add('active');
                        btn.textContent = '⏸';
                        loadWorkflowLists(selectedWorkflowId);
                    }
                });
            }
        }

        saveTimerState(cardId, active) {
            const minutes = parseInt(document.getElementById('timerMinutes').value);
            const sound = document.getElementById('timerSound').checked;

            const formData = new FormData();
            formData.append('action', 'update_card_timer');
            formData.append('card_id', cardId);
            formData.append('timer_minutes', minutes);
            formData.append('timer_active', active);
            formData.append('timer_sound', sound);

            return fetch('index.php', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    return true;
                }
                throw new Error(data.message);
            });
        }

        toggleDate(cardId) {
            const btn = document.querySelector('.date-start-btn');
            const isActive = btn.classList.contains('active');
            const dateEnd = document.getElementById('dateEnd');
            const dateValue = dateEnd.value;

            if (!dateValue) {
                alert('Selecione uma data primeiro');
                return;
            }

            this.saveDateState(cardId, !isActive).then(success => {
                if (success) {
                    btn.classList.toggle('active');
                    btn.textContent = isActive ? '▶' : '⏸';
                    const dateStatus = document.querySelector('.date-status');
                    dateStatus.textContent = isActive ? 'Inativo' : formatDate(dateValue);
                    loadWorkflowLists(selectedWorkflowId);
                }
            });
        }

        updateDate(cardId) {
            const dateEnd = document.getElementById('dateEnd');
            const dateValue = dateEnd.value;
            
            if (dateValue) {
                this.saveDateState(cardId, false).then(success => {  // Mudamos para false (inativo)
                    if (success) {
                        const btn = document.querySelector('.date-start-btn');
                        const dateStatus = document.querySelector('.date-status');
                        
                        // Atualiza visual para inativo
                        btn.classList.remove('active');
                        btn.textContent = '▶';
                        dateStatus.textContent = 'Inativo';
                        
                        // Atualiza a lista de cards
                        loadWorkflowLists(selectedWorkflowId);
                    }
                });
            }
        }

        saveDateState(cardId, active) {
            const dateEnd = document.getElementById('dateEnd');
            const dateSound = document.getElementById('dateSound');

            const formData = new FormData();
            formData.append('action', 'update_card_date');
            formData.append('card_id', cardId);
            formData.append('date_end', dateEnd.value);
            formData.append('date_active', active);
            formData.append('date_sound', dateSound.checked);

            return fetch('index.php', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    return true;
                }
                throw new Error(data.message);
            });
        }
    }

    // Inicialização
    const timeManager = new TimeManager();

    // Adicionar ao openEditCardModal existente
    function openEditCardModal(cardId) {
        const modal = document.getElementById('editCardModal');
        const nameInput = modal.querySelector('#editCardName');
        const descriptionInput = modal.querySelector('#editCardDescription');
        const confirmBtn = modal.querySelector('.confirm-btn');
        const cancelBtn = modal.querySelector('.cancel-btn');
        
        // Guarda referência ao card atual
        const cardElement = document.querySelector(`.card[data-card-id="${cardId}"]`);
        if (!cardElement) {
            console.error('Card não encontrado');
            return;
        }
        

        // Remove handlers antigos
        const newConfirmBtn = confirmBtn.cloneNode(true);
        const newCancelBtn = cancelBtn.cloneNode(true);
        confirmBtn.parentNode.replaceChild(newConfirmBtn, confirmBtn);
        cancelBtn.parentNode.replaceChild(newCancelBtn, cancelBtn);

        // Busca os dados do card
        fetch(`index.php?action=get_card&card_id=${cardId}`)
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    const cardData = data.card;
                    nameInput.value = cardData.nome;
                    descriptionInput.value = cardData.descricao;
                    
                    // Inicializa os controles de tempo
                    if (timeManager) {
                        timeManager.initializeTimeControls(cardId, {
                            end: cardData.timer_end,
                            active: cardData.timer_active === '1',
                            sound: cardData.timer_sound === '1'
                        }, {
                            end: cardData.date_end,
                            active: cardData.date_active === '1',
                            sound: cardData.date_sound === '1'
                        });
                    }

                    modal.classList.add('active');

                    // Adiciona novos handlers
                    newConfirmBtn.addEventListener('click', () => {
                        const formData = new FormData();
                        formData.append('action', 'update_card');
                        formData.append('card_id', cardId);
                        formData.append('nome', nameInput.value);
                        formData.append('descricao', descriptionInput.value);

                        fetch('index.php', {
                            method: 'POST',
                            body: formData
                        })
                        .then(response => response.json())
                        .then(data => {
                            if (data.success) {
                                modal.classList.remove('active');
                                loadWorkflowLists(selectedWorkflowId);
                            } else {
                                throw new Error(data.message || 'Erro ao atualizar card');
                            }
                        })
                        .catch(error => {
                            alert(error.message);
                        });
                    });

                    newCancelBtn.addEventListener('click', () => {
                        modal.classList.remove('active');
                    });
                }
            })
            .catch(error => {
                console.error('Erro ao carregar dados do card:', error);
            });
    }

    // Adicione esta função para configurar os event listeners dos cards
    function setupCardListeners(card) {
        // Botão de editar
        const editBtn = card.querySelector('.edit-card-btn');
        if (editBtn) {
            editBtn.addEventListener('click', (e) => {
                e.preventDefault();
                e.stopPropagation();
                const cardId = card.getAttribute('data-card-id');
                openEditCardModal(cardId);
            });
        }
    }

    // Função para adicionar listeners quando novos cards são criados
    function initializeCardListeners() {
        document.querySelectorAll('.card').forEach(card => {
            setupCardListeners(card);
        });
    }

    // Adicione ao DOMContentLoaded
    document.addEventListener('DOMContentLoaded', function() {
        // ... seu código existente ...
        
        // Inicializa os listeners dos cards
        initializeCardListeners();
    });

    // Adicione esta função para formatar o tempo restante
    function formatTimeRemaining(endTime) {
        const now = new Date();
        const end = new Date(endTime);
        const diff = end - now;

        if (diff <= 0) {
            return {
                text: 'Expirado',
                expired: true
            };
        }

        const minutes = Math.floor(diff / 60000);
        const seconds = Math.floor((diff % 60000) / 1000);
        return {
            text: `${minutes}:${seconds.toString().padStart(2, '0')}`,
            expired: false
        };
    }

    // Modificar a função existente que atualiza os timers
    function updateCardTimers() {
        const timerElements = document.querySelectorAll('.timer-remaining[data-timer-end]');
        
        timerElements.forEach(timer => {
            const endTime = timer.dataset.timerEnd;
            const status = formatTimeRemaining(endTime);
            
            timer.textContent = status.text;
            if (status.expired) {
                timer.classList.add('expired');
            } else {
                timer.classList.remove('expired');
            }
        });
    }

    // Adicione esta função para formatar a data
    function formatDate(dateString) {
        const date = new Date(dateString);
        // Ajusta para GMT-3
        const gmt3Date = new Date(date.getTime() - (3 * 60 * 60 * 1000));
        
        return gmt3Date.toLocaleString('pt-BR', {
            timeZone: 'UTC',
            day: '2-digit',
            month: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    // Modifique também a função calculateTimeRemaining para considerar GMT-3
    function calculateTimeRemaining(endTime) {
        const now = new Date();
        const end = new Date(endTime);
        // Ajusta ambas as datas para GMT-3
        const gmt3Now = new Date(now.getTime() - (3 * 60 * 60 * 1000));
        const gmt3End = new Date(end.getTime() - (3 * 60 * 60 * 1000));
        return gmt3End - gmt3Now;
    }

    // Adicione este listener logo após o DOMContentLoaded
    document.addEventListener('click', function(e) {
        // Se o clique não foi no botão do menu nem dentro do dropdown
        if (!e.target.matches('.list-menu-btn') && !e.target.closest('.list-menu-dropdown')) {
            // Fecha todos os dropdowns de menu
            document.querySelectorAll('.list-menu-dropdown').forEach(menu => {
                menu.style.display = 'none';
            });
        }
    });

    function openEditListModal(listId, currentName) {
        const modal = document.getElementById('editListModal');
        const input = modal.querySelector('#editListName');
        const confirmBtn = modal.querySelector('.confirm-btn');
        const cancelBtn = modal.querySelector('.cancel-btn');

        // Remove handlers antigos
        const newConfirmBtn = confirmBtn.cloneNode(true);
        const newCancelBtn = cancelBtn.cloneNode(true);
        confirmBtn.parentNode.replaceChild(newConfirmBtn, confirmBtn);
        cancelBtn.parentNode.replaceChild(newCancelBtn, cancelBtn);

        modal.classList.add('active');
        input.value = currentName;
        input.focus();

        // Adiciona novos handlers
        newConfirmBtn.addEventListener('click', async () => {
            const nome = input.value.trim();
            if (!nome) {
                alert('Por favor, digite um nome para a lista');
                return;
            }

            try {
                const formData = new FormData();
                formData.append('action', 'update_list');
                formData.append('list_id', listId);
                formData.append('nome', nome);

                const response = await fetch('index.php', {
                    method: 'POST',
                    body: formData
                });

                const data = await response.json();
                if (data.success) {
                    modal.classList.remove('active');
                    await loadWorkflowLists(selectedWorkflowId);
                } else {
                    throw new Error(data.message || 'Erro ao atualizar lista');
                }
            } catch (error) {
                alert(error.message);
            }
        });

        newCancelBtn.addEventListener('click', () => {
            modal.classList.remove('active');
        });
    }

    // Adicione este listener junto com os outros
    document.addEventListener('click', function(e) {
        if (e.target.matches('.list-menu-dropdown [data-action="edit"]')) {
            const listCard = e.target.closest('.list-card');
            const listId = listCard.dataset.listId;
            const listName = listCard.querySelector('h3').textContent;
            
            openEditListModal(listId, listName);
            
            // Fecha o menu dropdown
            const dropdown = e.target.closest('.list-menu-dropdown');
            dropdown.classList.remove('show');
        }
    });

    // Adicione apenas este listener após o DOMContentLoaded
    document.addEventListener('click', function(e) {
        // Verifica se clicou no botão de editar dentro do menu da lista
        if (e.target.closest('.list-menu-option')) {
            const option = e.target.closest('.list-menu-option');
            const text = option.textContent.trim().toLowerCase();
            
            if (text === 'editar') {
                const listCard = e.target.closest('.list-card');
                const listId = listCard.dataset.listId;
                const listName = listCard.querySelector('h3').textContent;
                
                openEditListModal(listId, listName);
                
                // Fecha o menu dropdown
                const dropdown = listCard.querySelector('.list-menu-dropdown');
                dropdown.classList.remove('show');
            }
        }
    });

    let workflowMenusInitialized = false;
    function initializeWorkflowMenu() {
        const btn = document.querySelector('.board-header .workflow-menu-btn');
        const menu = btn.nextElementSibling;

        btn.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();

            const rect = btn.getBoundingClientRect();
            
            // Fecha outros menus primeiro
            document.querySelectorAll('.workflow-menu-dropdown').forEach(m => {
                if (m !== menu && m.style.display === 'block') {
                    m.style.display = 'none';
                }
            });

            // Toggle deste menu
            const novoDisplay = menu.style.display === 'block' ? 'none' : 'block';
            menu.style.top = `${rect.bottom + 5}px`;
            menu.style.left = `${rect.left}px`;
            menu.style.display = novoDisplay;
        });

        // Handler global para fechar menus
        document.addEventListener('click', function(e) {
            if (!e.target.closest('.board-header')) {
                menu.style.display = 'none';
            }
        });
    }

    // Chame esta função após carregar o workflow
    initializeWorkflowMenu();

    // Função para renderizar os workflows
    function renderWorkflows(workflows) {
        console.group('🎨 Renderizando Workflows');
        console.log('Workflows recebidos:', workflows);
        
        const container = document.querySelector('.workflow-list');
        console.log('Container encontrado:', container);
        
        container.innerHTML = workflows.map(workflow => `
            <div class="workflow-item" data-id="${workflow.id}">
                <div class="workflow-name">${workflow.nome}</div>
                <div class="workflow-menu">
                    <button type="button" class="workflow-menu-btn" data-workflow-id="${workflow.id}">⋮</button>
                    <div class="workflow-menu-dropdown">
                        <div class="workflow-menu-option" data-action="edit">Editar</div>
                        <div class="workflow-menu-option" data-action="delete">Apagar</div>
                    </div>
                </div>
            </div>
        `).join('');
        
        console.log('HTML renderizado');
        
        // Chama explicitamente a inicialização dos menus
        console.log('Chamando initializeWorkflowMenus...');
        initializeWorkflowMenus();
        
        console.groupEnd();
    }

    // Na função que carrega os workflows
    function loadWorkflows() {
        console.group('📥 Carregando Workflows');
        
        fetch('index.php?action=get_workflows')
            .then(response => response.json())
            .then(data => {
                console.log('Dados recebidos:', data);
                if (data.success) {
                    console.log('Renderizando workflows...');
                    renderWorkflows(data.workflows);
                }
            })
            .catch(error => {
                console.error('❌ Erro ao carregar workflows:', error);
            })
            .finally(() => {
                console.groupEnd();
            });
    }

    function isDateExpired(dateString) {
        const now = new Date();
        const date = new Date(dateString);
        // Ajusta para GMT-3
        const gmt3Now = new Date(now.getTime() - (3 * 60 * 60 * 1000));
        const gmt3Date = new Date(date.getTime() - (3 * 60 * 60 * 1000));
        
        return gmt3Date < gmt3Now;
    }

    // Modificar a função existente updateDateStatus
    function updateDateStatus(dateEnd, dateStatus, isActive = true) {
        if (!dateEnd.value) return;
        
        if (isActive) {
            dateStatus.textContent = formatDate(dateEnd.value);
            if (isDateExpired(dateEnd.value)) {
                dateStatus.classList.add('expired');
                dateStatus.closest('.card-date').classList.add('expired');
            } else {
                dateStatus.classList.remove('expired');
                dateStatus.closest('.card-date').classList.remove('expired');
            }
        } else {
            dateStatus.textContent = 'Inativo';
            dateStatus.style.color = '#888';
        }
    }

    // Função para monitorar e atualizar status de datas
    function checkAndUpdateDates() {
        document.querySelectorAll('.card .date-end, .subcard .date-end').forEach(dateEl => {
            const dateValue = dateEl.dataset.dateEnd;
            if (dateValue) {
                const isExpired = isDateExpired(dateValue);
                const dateContainer = dateEl.closest('.card-date');
                
                if (isExpired) {
                    dateEl.classList.add('expired');
                    dateContainer.classList.add('expired');
                } else {
                    dateEl.classList.remove('expired');
                    dateContainer.classList.remove('expired');
                }
                dateEl.textContent = formatDate(dateValue);
            }
            
        });
    }

    function updateTimerDisplay(timerEl) {
        const endTime = new Date(timerEl.dataset.timerEnd).getTime();
        if (!endTime) return;

        const now = Date.now();
        const remaining = endTime - now;
        const timerContainer = timerEl.closest('.card-timer');
        const iconElement = timerContainer.querySelector('i');

        if (remaining <= 0) {
            timerEl.classList.add('expired');
            // Adiciona a classe ao container do timer também
            timerContainer.classList.add('expired');
            timerEl.textContent = 'Expirado';
            timerEl.setAttribute('data-expired', 'true');
        } else {
            timerEl.classList.remove('expired');
            // Remove a classe do container do timer também
            timerContainer.classList.remove('expired');
            timerEl.textContent = formatTimeRemaining(remaining);
            timerEl.setAttribute('data-expired', 'false');
        }
    }

    // Modificar o setInterval existente
    setInterval(() => {
        updateCardTimers();
        checkAndUpdateDates();
    }, 1000);

    // Adicione esta nova função
    function initializeAddCardButtons() {
        document.querySelectorAll('.add-card-btn').forEach(button => {
            button.addEventListener('click', function() {
                const listCard = this.closest('.list-card');
                if (listCard) {
                    const listId = listCard.dataset.listId;
                    openCardModal(listId);
                }
            });
        });
    }

    // Adicionar ao início do arquivo, junto com as outras funções de inicialização
    function initializeGlobalClickHandler() {
        // Remove handler anterior se existir
        document.removeEventListener('click', handleGlobalClick);
        
        // Define o handler como uma função nomeada para poder remover depois
        function handleGlobalClick(e) {
            if (!e.target.closest('.list-menu-container') && 
                !e.target.closest('.card-menu-container')) {
                
                document.querySelectorAll('.list-menu-dropdown.show, .card-menu.show').forEach(menu => {
                    menu.classList.remove('show');
                });
            }
        }

        // Adiciona o novo handler
        document.addEventListener('click', handleGlobalClick);
        
    }

    // Handler específico para fechar menus de workflow
    document.addEventListener('click', function(e) {
        if (!e.target.closest('.workflow-menu')) {
            document.querySelectorAll('.workflow-menu-dropdown').forEach(menu => {
                menu.style.display = 'none';
            });
        }
    });

    // Função para abrir o modal de edição do workflow
    function openEditWorkflowModal(workflowId, currentName) {
        console.log('Abrindo modal de edição para:', workflowId);
        const modal = document.getElementById('editWorkflowModal');
        const input = modal.querySelector('#editWorkflowName');
        const confirmBtn = modal.querySelector('.confirm-btn');
        const cancelBtn = modal.querySelector('.cancel-btn');

        // Remove handlers antigos
        const newConfirmBtn = confirmBtn.cloneNode(true);
        const newCancelBtn = cancelBtn.cloneNode(true);
        confirmBtn.parentNode.replaceChild(newConfirmBtn, confirmBtn);
        cancelBtn.parentNode.replaceChild(newCancelBtn, cancelBtn);

        modal.classList.add('active');
        input.value = currentName;
        input.focus();

        // Adiciona novos handlers
        newConfirmBtn.addEventListener('click', async () => {
            const nome = input.value.trim();
            if (!nome) {
                alert('Por favor, digite um nome para o workflow');
                return;
            }

            try {
                const formData = new FormData();
                formData.append('action', 'update_workflow');
                formData.append('workflow_id', workflowId);
                formData.append('nome', nome);

                const response = await fetch('index.php', {
                    method: 'POST',
                    body: formData
                });

                const data = await response.json();
                if (data.success) {
                    console.log('Workflow atualizado com sucesso');
                    modal.classList.remove('active');
                    window.location.reload();
                } else {
                    throw new Error(data.message || 'Erro ao atualizar workflow');
                }
            } catch (error) {
                alert(error.message);
            }
        });

        newCancelBtn.addEventListener('click', () => {
            modal.classList.remove('active');
        });
    }

    function deleteWorkflow(workflowId) {
        console.log('Tentando apagar workflow:', workflowId);
        if (!confirm('Tem certeza que deseja apagar este workflow?')) return;

        const formData = new FormData();
        formData.append('action', 'delete_workflow');
        formData.append('workflow_id', workflowId);

        fetch('index.php', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                console.log('Workflow apagado com sucesso');
                window.location.reload();
            } else {
                throw new Error(data.message || 'Erro ao apagar workflow');
            }
        })
        .catch(error => {
            alert(error.message);
        });
    }

    // Função para apagar o workflow
    function deleteWorkflow(workflowId) {
        console.log('Tentando apagar workflow:', workflowId);
        if (!confirm('Tem certeza que deseja apagar este workflow?')) return;

        const formData = new FormData();
        formData.append('action', 'delete_workflow');
        formData.append('workflow_id', workflowId);

        fetch('index.php', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                console.log('Workflow apagado com sucesso');
                window.location.reload();
            } else {
                throw new Error(data.message || 'Erro ao apagar workflow');
            }
        })
        .catch(error => {
            alert(error.message);
        });
    }

    document.addEventListener('DOMContentLoaded', () => {
        console.log('DOM completamente carregado e analisado');
        
        const workflowMenuOptions = document.querySelectorAll('.workflow-menu-option');
        console.log('Opções de menu encontradas:', workflowMenuOptions.length);

        workflowMenuOptions.forEach(option => {
            option.addEventListener('click', (event) => {
                console.log('Opção clicada:', event.target.textContent);
                const workflowItem = event.target.closest('.workflow-item');
                if (!workflowItem) {
                    console.error('Elemento workflow-item não encontrado');
                    return;
                }

                const workflowId = workflowItem.dataset.id;
                const workflowName = workflowItem.querySelector('.workflow-name').textContent;
                console.log('Workflow ID:', workflowId);
                console.log('Workflow Name:', workflowName);

                if (event.target.textContent.trim() === 'Editar') {
                    openEditWorkflowModal(workflowId, workflowName);
                } else if (event.target.textContent.trim() === 'Apagar') {
                    deleteWorkflow(workflowId);
                }
            });
        });
    });

    // Seletor do botão e dropdown do menu
    const workflowMenuBtn = document.querySelector('.workflow-menu-btn');
    const workflowMenuDropdown = document.querySelector('.workflow-menu-dropdown');
    
    // Event listener para abrir/fechar o menu
    workflowMenuBtn.addEventListener('click', (event) => {
        event.stopPropagation(); // Impede que o clique feche o menu imediatamente
        workflowMenuDropdown.classList.toggle('show');
        
        // Posiciona o dropdown abaixo do botão
        const btnRect = workflowMenuBtn.getBoundingClientRect();
        workflowMenuDropdown.style.top = `${btnRect.bottom}px`;
        workflowMenuDropdown.style.right = `${window.innerWidth - btnRect.right}px`;
    });

    // Fecha o menu ao clicar fora dele
    document.addEventListener('click', () => {
        workflowMenuDropdown.classList.remove('show');
    });

    // Event listeners para as opções do menu
    const workflowMenuOptions = document.querySelectorAll('.workflow-menu-option');
    workflowMenuOptions.forEach(option => {
        option.addEventListener('click', (event) => {
            const action = event.target.textContent.trim();
            const workflowId = document.querySelector('.selected-workflow').dataset.id;
            
            if (action === 'Editar') {
                openEditWorkflowModal(workflowId);
            } else if (action === 'Apagar') {
                deleteWorkflow(workflowId);
            }
            
            workflowMenuDropdown.classList.remove('show');
        });
    });

    // Adicione esta função
    function initializeSubcardButtons() {
        document.querySelectorAll('.add-subcard-btn').forEach(button => {
            button.addEventListener('click', function() {
                const card = this.closest('.card');
                const listCard = card.closest('.list-card');
                if (card && listCard) {
                    const parentId = card.dataset.cardId;
                    const listId = listCard.dataset.listId;
                    openCardModal(listId, parentId);
                }
            });
        });
    }

    

    });
