document.addEventListener("DOMContentLoaded", function() {
    const counterElement = document.getElementById("counter");
    const functionAppUrl = ' http://localhost:7071/api/http_trigger'; // Replace with your function app URL

    // Function to fetch the current visitor count
    async function getVisitorCount() {
        try {
            const response = await fetch(functionAppUrl, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error('Network response was not ok');
            }

            const data = await response.json();
            return data.count;  // Assuming your function returns { "count": <current_count> }
        } catch (error) {
            console.error('Failed to fetch visitor count:', error);
            return null;
        }
    }

    // Function to update the visitor count
    async function updateVisitorCount() {
        try {
            const response = await fetch(functionAppUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error('Network response was not ok');
            }

            const data = await response.json();
            return data.count;  // Assuming your function returns { "count": <updated_count> }
        } catch (error) {
            console.error('Failed to update visitor count:', error);
            return null;
        }
    }

    // Function to display and update the visitor count
    async function displayVisitorCount() {
        let count = await getVisitorCount();
        if (count !== null) {
            counterElement.textContent = `Visitors: ${count}`;
            count = await updateVisitorCount();
            if (count !== null) {
                counterElement.textContent = `Visitors: ${count}`;
            }
        } else {
            counterElement.textContent = 'Error loading visitor count';
        }
    }

    // Call the displayVisitorCount function on page load
    displayVisitorCount();
});
