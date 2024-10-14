document.addEventListener('DOMContentLoaded', function() {
  // event collection ---------------------------------------------------------------------------------------------
  document.querySelectorAll('div[data-send-on-change="1"]').forEach(function(element) {
      
    // lost focus for input
    const inputElement = element.querySelector('input');
    if (inputElement) {
      inputElement.addEventListener('focusout', function() {
          sendData([element]);
      });

      // enter keydown for input
      inputElement.addEventListener('keydown', function(event) {
          if (event.key === 'Enter') {
              sendData([element]);
          }
      });
    }

    const buttonElement = element.querySelector('button');
    if (buttonElement) {
      buttonElement.addEventListener('click', function(event) {
        sendData([element]);
      });
    }

  });

});

// function for sending data for write
function sendData(elements) {
  // create main structure for send
  let datatosend = {
    sendingdatapacks: [],
    url: window.location.href
  };

  elements.forEach(element => {
    // get atribute data
    const elementType = element.getAttribute('data-element-type');
    const upiTrigger = element.getAttribute('data-upi-trigger');
    const generalDataLink = element.getAttribute('data-generaldatalink');
    const clickAction = element.getAttribute('data-click-action');
    const inheritedValues = element.getAttribute('data-inherited-values');

    // get element value
    elementValue = element.querySelector('input, textarea, select') 
      ? element.querySelector('input, textarea, select').value 
      : element.textContent;

    var loginvalues = ""
    
    if (clickAction == "login") {
      loginvalues = "";

      document.querySelectorAll('div[data-upi-onsave="loginname"]').forEach(function(secelement) {
        secelementValue = secelement.querySelector('input, textarea, select') 
          ? secelement.querySelector('input, textarea, select').value 
          : secelement.textContent;
        loginvalues = secelementValue + ";";
      });

      document.querySelectorAll('div[data-upi-onsave="loginpassword"]').forEach(function(secelement) {
        secelementValue = secelement.querySelector('input, textarea, select') 
          ? secelement.querySelector('input, textarea, select').value 
          : secelement.textContent;
        loginvalues = loginvalues + secelementValue;
      });

      elementValue = loginvalues;
    }

    console.log("clickAction:" + clickAction + ";");
    if (clickAction == "register") {
      loginvalues = "";

      document.querySelectorAll('div[data-upi-onsave="registername"]').forEach(function(secelement) {
        secelementValue = secelement.querySelector('input, textarea, select') 
          ? secelement.querySelector('input, textarea, select').value 
          : secelement.textContent;
        loginvalues = secelementValue + ";";
      });

      document.querySelectorAll('div[data-upi-onsave="registerpassword"]').forEach(function(secelement) {
        secelementValue = secelement.querySelector('input, textarea, select') 
          ? secelement.querySelector('input, textarea, select').value 
          : secelement.textContent;
        loginvalues = loginvalues + secelementValue;
      });

      console.log("elementValue:" + elementValue + ";");
      elementValue = loginvalues;
    }


    datatosend.sendingdatapacks.push({
      element_type: elementType,
      upi_trigger: upiTrigger,
      generaldatalink: generalDataLink,
      click_action: clickAction,
      inherited_values: inheritedValues,
      value: elementValue
    });
  });

  // AJAX requirement using fetch API
  fetch('/data_incoming', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    },
    body: JSON.stringify(datatosend)
  })
  .then(response => response.json())
  .then(data => {
    // answer obtain list of triggered upis
    data.triggeredupistoload.forEach(triggered => {
      invokedataloadofelements(triggered);
    });
    data.triggeredupistosave.forEach(triggered => {
      invokedatasaveofelements(triggered);
    });
    data.triggeredredirs.forEach(triggered => {
      //make redir to page
      let currentUrl = new URL(window.location);
      currentUrl.searchParams.set('page', triggered);
      window.location.href = currentUrl.toString();
    });
  })
  .catch(error => {
    console.error('outcoming data rejected:', error);
  });
}
  
function invokedataloadofelements(triggering_upi) {
  // look for every element, who has same upi. now we are using receive upi, because we need to receive data

  if (triggering_upi === "reload") {
    location.reload(); // reload page
  }

  const elementsToUpdate = document.querySelectorAll(`[data-upi-receive="${triggering_upi}"]`);
  
  totaldatablockstosend = 0;

  // create main structure for send
  let datatosend = {
    sendingdatapacks: [],
    url: window.location.href
  };


  // now we pass every element matching receive upu
  elementsToUpdate.forEach(element => {
    const element_id = element.getAttribute('data-element-id');
    const element_gdl = element.getAttribute('data-generaldatalink');
    const element_inhvalues = element.getAttribute('data-inherited-values');

    const dataPackage = {
      element_id: element_id,
      element_gdl: element_gdl,
      element_inhvalues: element_inhvalues
    };

    // add data package
    datatosend.sendingdatapacks.push(dataPackage);

    totaldatablockstosend = totaldatablockstosend + 1;
  });

  if (totaldatablockstosend > 0) {
    fetch('/query_incoming', {
      method: 'POST',
      headers: {
          'Content-Type': 'application/json',
      },
      body: JSON.stringify(datatosend) // Převedení pole balíčků na JSON
    })
    .then(response => {
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        return response.json();
    })
    .then(data => {
      data.answeredqueries.forEach(item => {
          const incoming_element_id = item.element_id;
          const incoming_value = item.value;

          if (incoming_value != "#") {
            // now we are looking for every element matching element-id. There can be more same elements
            const elementsToUpdate = document.querySelectorAll(`[data-element-id="${incoming_element_id}"]`);
            elementsToUpdate.forEach(elementToUpdate => {
                // this element should be updated
                const updatedElementType = elementToUpdate.getAttribute('data-element-type');

                switch (updatedElementType){
                  case "1":
                    elementToUpdate.textContent = incoming_value; 
                    break;
                  case "8":
                    elementToUpdate.innerHTML = "<h3>" + incoming_value + "</h3>";
                    break;
                  case "3":
                    const imgElement = elementToUpdate.querySelector('img');

                    imgElement.setAttribute('src', incoming_value);
                    // new load of image
                    imgElement.onload = () => {
                      imgElement.style.display = 'none'; 
                      imgElement.offsetHeight;
                      imgElement.style.display = '';
                    };
                    break;
                  case "4":
                    const inputElement = elementToUpdate.querySelector('input');
                    inputElement.value = incoming_value;
                    break;
                }
            });
          }
      });
    })
    .catch((error) => {
        console.error('Error:', error);
    });
  }
}

function invokedatasaveofelements(triggering_upi) {
  // look for every element, who has same upi. now we are using onsave upi, because we need to send data
  const elementsToUpdate = document.querySelectorAll(`[data-upi-onsave="${triggering_upi}"]`);
  if (elementsToUpdate.length > 0) {
    sendData(elementsToUpdate);
  }
}
  


